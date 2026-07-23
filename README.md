# Serverless Cloud Portfolio — AWS Cloud Resume Challenge

**Live site:** [alfiyajaved.in](https://alfiyajaved.in)
**Status:** In Progress — actively extending with Terraform (IaC) and GitHub Actions (CI/CD)

A fully serverless personal portfolio built to avoid traditional server management, integrating 4+ AWS managed services for scalable frontend and backend hosting.

## What This Solves

A reliable, low-maintenance personal portfolio — architected entirely serverless on AWS instead of relying on a traditional always-on server.

## Architecture

**Frontend path (load website):**
```
User types alfiyajaved.in
→ Route 53 resolves domain
→ returns CloudFront address
→ Browser connects to CloudFront
→ CloudFront checks cache: hit? serve it. miss? fetch from S3
→ HTML/CSS/JS delivered to browser
```

**Backend path (visitor count):**
```
JavaScript in the browser calls API Gateway endpoint
→ API Gateway receives the HTTP request
→ API Gateway invokes the Lambda function
→ Lambda runs Python code, calls DynamoDB via boto3
→ DynamoDB increments counter, returns new value
→ Lambda returns value → API Gateway → JavaScript → displayed on page
```

| Layer | Service |
|---|---|
| Frontend hosting | S3 (static website hosting) |
| CDN & DNS | CloudFront + Route 53 |
| HTTPS | AWS Certificate Manager (ACM) |
| API | API Gateway |
| Compute | AWS Lambda (Python + boto3) |
| Database | DynamoDB |
| IaC (in progress) | Terraform |

See [`MANUAL_ARCHITECTURE.md`](./MANUAL_ARCHITECTURE.md) for the full manual build notes and IAM policy details.

## Highlights

- Integrated **4+ managed AWS services** (S3, CloudFront, Route 53, ACM, API Gateway, Lambda, DynamoDB) for a fully serverless, scalable setup — no servers to patch or manage.
- Built a **Python Lambda function** integrated with API Gateway and DynamoDB to deliver a real-time visitor counter — hands-on serverless, event-driven design.
- Configured **custom domain routing and HTTPS** via Route 53 and ACM; troubleshot DNS/SSL/TLS issues by isolating browser-level caching from infrastructure-layer problems, improving deployment reliability.
- **Under $1/month operating cost** by strategically selecting AWS free-tier services throughout.
- Currently **importing manually-created AWS resources into Terraform-managed state** — converting a console-first build into Infrastructure as Code.
- **GitHub Actions CI/CD** planned next.

## Repo Structure

```
├── Backend/       → Lambda function code (Python)
├── Frontend/       → Static site (HTML/CSS/JS)
├── Terraform/      → IaC — importing existing manual resources
├── .github/        → CI/CD workflows (in progress)
└── MANUAL_ARCHITECTURE.md → Full manual-build documentation + IAM policy
```

## Build Log

I'm documenting the full build process — including the manual-to-IaC migration — on [Hashnode](#).

## Tech Stack

AWS (S3, CloudFront, Route 53, ACM, API Gateway, Lambda, DynamoDB) · Python · Boto3 · Terraform · GitHub Actions