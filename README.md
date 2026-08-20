# Cloud Resume Challenge — Serverless Portfolio on AWS
 
A personal portfolio website built entirely on AWS managed and serverless services. This project is part of the Cloud Resume Challenge. It includes a live backend feature (a visitor counter), infrastructure managed as code with Terraform, and automated unit tests.
 
**Live site:** [alfiyajaved.in](https://alfiyajaved.in)

---
 
## About This Project
 
I built this to learn AWS by deploying something real, not just following theory. It started as a static portfolio site and grew to include a serverless backend, infrastructure as code, and automated testing. I am currently finishing the last parts of the infrastructure in Terraform and building a CI/CD pipeline next.
 
I document the real bugs and decisions behind this project on my blog: [alfiyajaved.hashnode.dev](https://alfiyajaved.hashnode.dev)
 
---

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