# Cloud Resume Challenge — Serverless Portfolio on AWS
 
A personal portfolio website built entirely on AWS managed and serverless services. This project is part of the Cloud Resume Challenge. It includes a live backend feature (a visitor counter), infrastructure managed as code with Terraform, and automated unit tests.
 
**Live site:** [alfiyajaved.in](https://alfiyajaved.in)


---
 

## About This Project
 
I built this to learn AWS by deploying something real, not just following theory. It started as a static portfolio site and grew to include a serverless backend, infrastructure as code, and automated testing. I am currently finishing the last parts of the infrastructure in Terraform and building a CI/CD pipeline next.
 
I document the real bugs and decisions behind this project on my blog: [alfiyajaved.hashnode.dev](https://alfiyajaved.hashnode.dev)
 

---


## Architecture
 
![Architecture Diagram](./assets/architecture-diagram.png)
 
The project has two separate paths.
 
**Frontend path** — delivers the static site.
`User → Route 53 → CloudFront → S3`
 
**Backend path** — powers the visitor counter.
`Browser (JavaScript) → API Gateway → Lambda → DynamoDB`
 
The S3 bucket is private. It can only be reached through CloudFront, using Origin Access Control (OAC). The bucket cannot be accessed directly from the internet.
 


 ---


## Tech Stack
 
| Layer | Service | Purpose |
|---|---|---|
| Hosting | S3 | Stores the static site files (HTML, CSS, JS) |
| CDN | CloudFront | Delivers the site with caching and HTTPS |
| DNS | Route 53 | Points the domain to CloudFront |
| SSL/TLS | ACM | Provides the HTTPS certificate |
| API | API Gateway (HTTP API) | Exposes the visitor counter endpoint |
| Compute | Lambda (Python 3.14) | Runs the visitor counter logic |
| Database | DynamoDB | Stores the visitor count (on-demand billing) |
| Infrastructure as Code | Terraform | Manages AWS resources as code |
| Testing | pytest, unittest.mock | Tests the Lambda function without touching real AWS resources |

See [`MANUAL_ARCHITECTURE.md`](./MANUAL_ARCHITECTURE.md) for the full manual build notes.
 


---


## API Reference
 
| Method | Endpoint | Description | Response |
|---|---|---|---|
| GET | `/count` | Increments and returns the current visitor count | `{ "visitor_count": <number> }` |
 
---


## Project Structure
 
```
Cloud_Resume_Project
├── frontend/                 
│   ├── index.html            # HTML file
│   ├── style.css             # CSS file
│   └── visitor.js            # javascript file
├── Backend/
│   ├── lambda_function.py    # Lambda handler for the visitor counter
│   └── test_lambda.py        # Unit tests for the Lambda function
├── terraform/
│   ├── main.tf                # Resource definitions
│   ├── providers.tf           # Provider and version configuration
│   ├── outputs.tf             # Output values
│   ├── variables.tf           # variable declaration
│   └── 
│   └── build/                 # Generated Lambda deployment package (gitignored)
├── assets                     # Images 
│    
├── MANUAL_ARCHITECTURE.md     #Manually built architecture file
└── README.md
```

---
 
 
## Prerequisites
 
Install the following before deploying this project.
 
### Python
 
Python 3.14 is required, to match the Lambda runtime. Create and activate a virtual environment before running any Python commands:
 
```bash
python3 -m venv venv
source venv/bin/activate      # Linux / Mac
venv\Scripts\activate         # Windows
```
 
No external packages are required to run the tests, since boto3 is mocked directly inside the test file. If real dependencies are added later, list them in a `requirements.txt` file.

### AWS CLI
 
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```
 
For other operating systems, see the [official AWS CLI install guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
 
### Terraform
 
Terraform reads AWS credentials through the AWS CLI's profile system, so AWS CLI should be configured before Terraform is used.
 
```bash
sudo apt update && sudo apt install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
terraform -version
```
 
For other operating systems, see the [official HashiCorp install guide](https://developer.hashicorp.com/terraform/downloads).



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