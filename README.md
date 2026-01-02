# Cloud Quizzer – Flask + AWS

Production-friendly quiz web app with Flask backend (EC2), DynamoDB persistence, S3-hosted static frontend, and Terraform IaC.

## Project Layout
- [run.py](run.py) entrypoint
- [app/__init__.py](app/__init__.py) Flask factory + env loading + Jinja filters
- [app/routes.py](app/routes.py) HTML + JSON APIs (`/start`, `/quiz/<topic>`, `/submit`, `/scoreboard`)
- [app/services/dynamo.py](app/services/dynamo.py) DynamoDB reads/writes
- [app/data/questions.json](app/data/questions.json) topic-wise questions
- [app/templates/](app/templates) server-rendered UI
- [app/static/](app/static) styling assets
- [frontend/](frontend) S3-ready static UI calling JSON endpoints
- [infra/](infra) Terraform for EC2, DynamoDB, S3
- [.env.example](.env.example) required environment variables
- [requirements.txt](requirements.txt)

## Prerequisites
- Python 3.10+
- AWS credentials with permissions for EC2, DynamoDB, S3, IAM (for bucket policy)
- Terraform ≥ 1.5
- AWS CLI v2

## Local Development
```bash
cp .env.example .env  # fill with your AWS creds/region/table names
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python run.py  # http://localhost:5000
```

## API (JSON-friendly)
- `POST /start` `{username, topic}` → `{message}`
- `GET /quiz/<topic>?format=json` → `{topic, title, questions}`
- `POST /submit?format=json` `{username, topic, answers}` → `{score, total, attempt_id}`
- `GET /scoreboard?format=json[&topic=]` → `{scores, topics}`

## Terraform (from Codespaces)
```bash
cd infra
terraform init
terraform apply -var "ec2_key_name=YOUR_KEYPAIR" -var "s3_bucket_name=unique-quiz-bucket" -auto-approve
```
Outputs include EC2 public IP and S3 website endpoint.

## Deploy Backend to EC2
```bash
EC2=YOUR_EC2_PUBLIC_IP
scp -i ~/.ssh/YOUR_KEY -r app run.py requirements.txt .env ubuntu@$EC2:/opt/quiz-app
ssh -i ~/.ssh/YOUR_KEY ubuntu@$EC2 <<'EOF'
	cd /opt/quiz-app
	sudo pip3 install -r requirements.txt
	sudo systemctl restart quiz.service
	sudo systemctl status quiz.service --no-pager
EOF
```
Service file is pre-created via EC2 user_data (see [infra/main.tf](infra/main.tf)).

## Deploy Static Frontend to S3
```bash
AWS_REGION=us-east-1
BUCKET=unique-quiz-bucket
aws s3 sync frontend s3://$BUCKET --delete
aws s3 website s3://$BUCKET/ --index-document index.html --error-document index.html
```
Open the Terraform output `s3_website_endpoint` and set the API base URL in the page to your EC2 IP (`http://<EC2_IP>:5000`).

## DynamoDB Tables
- Users: `quiz_attempt_id` (PK), stores attempts/answers
- Scores: `topic` (PK), `score_key` (SK padded for descending ordering), stores leaderboard rows

## Environment Variables
See [.env.example](.env.example): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `DYNAMO_USERS_TABLE`, `DYNAMO_SCORES_TABLE`, `SECRET_KEY`, `QUESTION_FILE`.

## Useful AWS CLI Snippets
```bash
# Verify Dynamo tables
aws dynamodb list-tables
# Tail leaderboard items
aws dynamodb scan --table-name quiz_scores --max-items 5
# SSH tunnel for local preview of EC2 service
ssh -i ~/.ssh/YOUR_KEY -L 5000:localhost:5000 ubuntu@$EC2
```

## Notes
- S3 static UI talks to JSON endpoints; Flask templates work for server-rendered mode on EC2.
- Questions are JSON-driven; add topics/questions in [app/data/questions.json](app/data/questions.json) and redeploy.
- For production harden security groups, add HTTPS (ALB/ACM), and move secrets to SSM Parameter Store.