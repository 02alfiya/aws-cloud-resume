"""Visitor counter Lambda.

Structured JSON logging, EMF custom metrics (no extra IAM needed),
and milestone announcements every Nth visitor.
"""

import json
import logging
import os
import sys
import time
from datetime import datetime, timezone

import boto3

SERVICE_NAME = os.environ.get("SERVICE_NAME", "visitor-counter")
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()
METRICS_NAMESPACE = os.environ.get("METRICS_NAMESPACE", "CloudResume")

_COLD_START = True


class JsonFormatter(logging.Formatter):
    """Renders every log record as a single-line JSON object."""

    def format(self, record):
        payload = {
            "timestamp": datetime.fromtimestamp(
                record.created, tz=timezone.utc
            ).isoformat(timespec="milliseconds"),
            "level": record.levelname,
            "service": SERVICE_NAME,
            "message": record.getMessage(),
        }
        details = getattr(record, "details", None)
        if details:
            payload.update(details) 
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload, default=str)


class _StdoutHandler(logging.StreamHandler):
    """Always writes to whatever sys.stdout is *right now*.

    Keeps logs on the Lambda runtime's stdout and lets tests capture
    output cleanly with contextlib.redirect_stdout.
    """

    def __init__(self):
        super().__init__(stream=sys.stdout)

    @property
    def stream(self):
        return sys.stdout

    @stream.setter
    def stream(self, value):
        pass  # StreamHandler.__init__ assigns this; we override dynamically


def _configure_logger():
    root = logging.getLogger()
    root.setLevel(LOG_LEVEL)
    if not root.handlers:
        root.addHandler(_StdoutHandler())
    for handler in root.handlers:
        handler.setFormatter(JsonFormatter())
    return logging.getLogger(SERVICE_NAME)


LOGGER = _configure_logger()


def emit_metric(name, value, unit="Count"):
    """Publish a custom metric via CloudWatch Embedded Metric Format.

    The metric rides inside the log stream — CloudWatch extracts it
    automatically. No PutMetricData call, no extra IAM permission.
    """
    print(json.dumps({
        "_aws": {
            "Timestamp": int(time.time() * 1000),
            "CloudWatchMetrics": [{
                "Namespace": METRICS_NAMESPACE,
                "Dimensions": [],
                "Metrics": [{"Name": name, "Unit": unit}],
            }],
        },
        name: value,
    }))


dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ.get("VISITOR_TABLE", "visitor_count"))


def announce_milestone(new_count, request_id):
    """Log, graph, and notify every Nth visitor."""
    step = int(os.environ.get("MILESTONE_STEP", "100"))
    if step <= 0 or new_count % step != 0:
        return

    LOGGER.info("visitor milestone reached", extra={"details": {
        "milestone": new_count,
        "step": step,
        "request_id": request_id,
    }})
    emit_metric("VisitorMilestone", new_count)

    topic_arn = os.environ.get("MILESTONE_TOPIC_ARN")
    if not topic_arn:
        return
    try:
        boto3.client("sns").publish(
            TopicArn=topic_arn,
            Subject=f"Milestone: {new_count} visitors on alfiyajaved.in",
            Message=json.dumps({
                "milestone": new_count,
                "message": f"The visitor counter just crossed {new_count}.",
            }, indent=2),
        )
    except Exception as exc:
        # A failed notification must never fail the visitor's request.
        LOGGER.error("milestone notification failed", extra={"details": {
            "error_type": type(exc).__name__,
            "error": str(exc),
        }})


def lambda_handler(event, context):
    global _COLD_START
    started = time.perf_counter()
    request_id = getattr(context, "aws_request_id", "unknown")
    cold_start, _COLD_START = _COLD_START, False
    http = event.get("requestContext", {}).get("http", {})

    LOGGER.info("request received", extra={"details": {
        "request_id": request_id,
        "cold_start": cold_start,
        "method": http.get("method", "GET"),
        "path": http.get("path", "/count"),
        "source_ip": http.get("sourceIp", "unknown"),
        "user_agent": http.get("userAgent", "unknown"),
    }})

    try:
        response = table.update_item(
            Key={"id": "count"},
            UpdateExpression="ADD #c :inc",
            ExpressionAttributeNames={"#c": "count"},
            ExpressionAttributeValues={":inc": 1},
            ReturnValues="UPDATED_NEW",
        )
        new_count = int(response["Attributes"]["count"])
        duration_ms = round((time.perf_counter() - started) * 1000, 2)

        emit_metric("VisitorCount", new_count)
        LOGGER.info("visitor count updated", extra={"details": {
            "request_id": request_id,
            "previous_count": new_count - 1,
            "new_count": new_count,
            "duration_ms": duration_ms,
        }})

        announce_milestone(new_count, request_id)

        return {
            "statusCode": 200,
            "body": json.dumps({"visitor_count": new_count}),
        }

    except Exception as exc:
        duration_ms = round((time.perf_counter() - started) * 1000, 2)
        LOGGER.error("visitor counter failed", extra={"details": {
            "request_id": request_id,
            "error_type": type(exc).__name__,
            "error": str(exc),
            "duration_ms": duration_ms,
        }}, exc_info=True)
        emit_metric("HandlerError", 1)
        # Re-raise (don't swallow): keeps the AWS/Lambda Errors metric —
        # and the alarm you already built on it — accurate.
        raise