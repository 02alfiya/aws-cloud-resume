import io
import json
import os
import sys
import unittest
from contextlib import redirect_stdout
from unittest.mock import MagicMock

os.environ['AWS_DEFAULT_REGION'] = 'us-east-1'
os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'

mock_boto3 = MagicMock()
sys.modules['boto3'] = mock_boto3

import lambda_function


class TestLambda(unittest.TestCase):

    def setUp(self):
        mock_boto3.resource.reset_mock()
        mock_boto3.client.reset_mock()
        self.mock_table = mock_boto3.resource.return_value.Table.return_value
        self.mock_table.reset_mock()
        self.mock_table.update_item.side_effect = None
        os.environ.pop('MILESTONE_TOPIC_ARN', None)
        os.environ.pop('MILESTONE_STEP', None)

    def _invoke(self, count):
        self.mock_table.update_item.return_value = {'Attributes': {'count': count}}
        return lambda_function.lambda_handler({}, {})

    def test_lambda_handler_success(self):
        buf = io.StringIO()
        with redirect_stdout(buf):
            response = self._invoke(5)

        self.assertEqual(response['statusCode'], 200)
        self.assertEqual(json.loads(response['body'])['visitor_count'], 5)

        self.mock_table.update_item.assert_called_once_with(
            Key={'id': 'count'},
            UpdateExpression='ADD #c :inc',
            ExpressionAttributeNames={'#c': 'count'},
            ExpressionAttributeValues={':inc': 1},
            ReturnValues='UPDATED_NEW'
        )

        # EMF custom metric was emitted
        self.assertIn('"VisitorCount"', buf.getvalue())

    def test_milestone_emits_metric_and_notifies_sns(self):
        os.environ['MILESTONE_STEP'] = '5'
        os.environ['MILESTONE_TOPIC_ARN'] = 'arn:aws:sns:us-east-2:046276255165:cloud-resume-milestones'

        buf = io.StringIO()
        with redirect_stdout(buf):
            response = self._invoke(10)

        self.assertEqual(response['statusCode'], 200)
        self.assertIn('"VisitorMilestone"', buf.getvalue())

        mock_boto3.client.assert_called_with('sns')
        publish_kwargs = mock_boto3.client.return_value.publish.call_args.kwargs
        self.assertIn('10 visitors', publish_kwargs['Subject'])

    def test_non_milestone_does_not_notify(self):
        self._invoke(7)
        mock_boto3.client.return_value.publish.assert_not_called()

    def test_dynamodb_failure_logs_structured_error_and_reraises(self):
        self.mock_table.update_item.side_effect = Exception('dynamodb is down')

        buf = io.StringIO()
        with redirect_stdout(buf):
            with self.assertRaises(Exception):
                lambda_function.lambda_handler({}, {})

        self.assertIn('"level": "ERROR"', buf.getvalue())
        self.assertIn('dynamodb is down', buf.getvalue())
        self.assertIn('"HandlerError"', buf.getvalue())
        self.mock_table.update_item.side_effect = None


if __name__ == '__main__':
    unittest.main()