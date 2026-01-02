# Cloud Quizzer – Deployment Guide

## ✅ Live Deployment Status

Your 3-tier Quiz application is now **LIVE on AWS**!

### Infrastructure Details

| Component | Details |
|-----------|---------|
| **EC2 Backend** | `13.202.91.241:5000` (ap-south-1, t3.micro) |
| **S3 Frontend** | `quizz-app-3tier-1767359826.s3-website.ap-south-1.amazonaws.com` |
| **DynamoDB** | `quiz_users` (PK: quiz_attempt_id), `quiz_scores` (PK: topic, SK: score_key) |
| **Region** | ap-south-1 (Mumbai) |
| **Key Pair** | `quiz-deploy-key` |
| **Security Group** | `quiz-app-sg` (HTTP 80, HTTPS 443, Flask 5000, SSH 22 open) |

---

## 🔗 How They're Connected

### 1. **EC2 → DynamoDB**
- Flask backend reads `.env` for AWS credentials and table names
- Boto3 client authenticated via `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- **Service:** `app/services/dynamo.py` (DynamoService class)
- **Operations:**
  - `record_attempt()` – writes quiz submissions to `quiz_users` and `quiz_scores`
  - `top_scores()` – reads leaderboard from `quiz_scores`

### 2. **S3 ↔ EC2 (Frontend → Backend)**
- Static HTML/CSS/JS frontend hosted on S3
- JavaScript fetches JSON from Flask API endpoints
- User sets API base URL: `http://13.202.91.241:5000`
- **Endpoints used:**
  - `GET /quiz/<topic>?format=json` – fetch questions
  - `POST /submit?format=json` – submit answers
  - `GET /scoreboard?format=json` – fetch leaderboard

### 3. **S3 Public Access**
- Bucket policy allows public read on `quizz-app-3tier-1767359826`
- Website configuration enabled (index: `index.html`, error: `index.html`)
- Static files uploaded via `aws s3 sync`

---

## 🚀 Access Points

### **For End Users:**
1. Open S3 website: `http://quizz-app-3tier-1767359826.s3-website.ap-south-1.amazonaws.com`
2. Set API Base URL to: `http://13.202.91.241:5000`
3. Take a quiz → answers saved to DynamoDB

### **For Administration:**
- **SSH to EC2:** `ssh -i /tmp/quiz-deploy-key.pem ec2-user@13.202.91.241`
- **View Flask logs:** `sudo journalctl -u quiz.service -f`
- **Restart service:** `sudo systemctl restart quiz.service`
- **Query DynamoDB:** `aws dynamodb scan --table-name quiz_users --max-items 10`

---

## 📋 Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                  User's Browser                          │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
   ┌────▼────────┐          ┌────▼──────────────┐
   │   S3 Site   │          │  Flask API (5000) │
   │  (Static)   │◄────────►│  (EC2 13.x.x.x)   │
   └─────────────┘ JSON     └────┬──────────────┘
                                  │
                                  │ Boto3
                                  │
                           ┌──────▼──────────┐
                           │   DynamoDB      │
                           │  quiz_users     │
                           │  quiz_scores    │
                           └─────────────────┘
```

---

## 📝 Data Flow Example

**User Takes Quiz:**
1. Frontend loads `http://13.202.91.241:5000/quiz/python?format=json`
2. Flask fetches from `app/data/questions.json`, returns JSON
3. User answers and submits to `POST /submit?format=json`
4. Flask validates answers, calls `dynamo.record_attempt()`
5. Boto3 writes to:
   - `quiz_users` – stores attempt ID, answers, score
   - `quiz_scores` – stores leaderboard entry
6. Response returned to frontend
7. Frontend fetches leaderboard via `GET /scoreboard?format=json`
8. User sees real-time scores from DynamoDB

---

## 🔐 Security & Production Considerations

- **Credentials:** Currently in `.env` on EC2. For production:
  - Use AWS Systems Manager Parameter Store or Secrets Manager
  - Remove `.env` from repository
  - Use IAM roles for EC2 instead of access keys
  
- **HTTPS:** Use AWS Certificate Manager + ALB or CloudFront
  
- **Rate Limiting:** Add Flask-Limiter to prevent abuse

- **CORS:** Currently open to all origins (for S3); restrict in production

- **DynamoDB:** Currently on-demand billing; monitor for cost

---

## 🛠️ Maintenance Commands

### **Check service status:**
```bash
ssh -i /tmp/quiz-deploy-key.pem ec2-user@13.202.91.241
sudo systemctl status quiz.service
```

### **View recent logs:**
```bash
sudo journalctl -u quiz.service --since "30 minutes ago"
```

### **Restart service:**
```bash
sudo systemctl restart quiz.service
```

### **Update frontend (after changes to frontend/ folder):**
```bash
aws s3 sync frontend s3://quizz-app-3tier-1767359826 --delete
```

### **Update backend code:**
```bash
scp -i /tmp/quiz-deploy-key.pem -r app/ run.py ec2-user@13.202.91.241:/opt/quiz-app/
ssh -i /tmp/quiz-deploy-key.pem ec2-user@13.202.91.241 sudo systemctl restart quiz.service
```

### **Query quiz attempts:**
```bash
aws dynamodb scan --table-name quiz_users --max-items 20
```

### **Query leaderboard:**
```bash
aws dynamodb query --table-name quiz_scores \
  --key-condition-expression "topic = :topic" \
  --expression-attribute-values '{":topic":{"S":"python"}}' \
  --scan-index-forward false
```

---

## 📊 Costs Estimate (Monthly)

| Service | Free Tier | Cost |
|---------|-----------|------|
| **EC2 (t3.micro, 1 month)** | 750 hrs/month | ~$3–5 USD |
| **DynamoDB (on-demand)** | 25 GB storage | ~$1–2 USD (pay-per-request) |
| **S3 (website)** | 5 GB storage | ~$0.10 USD (storage only) |
| **Data transfer** | 1 GB/month | ~$0 (under free tier) |
| **Total (within free tier)** | – | **~$0–5 USD** |

---

## 🔄 Next Steps

1. **Add more quizzes:** Edit `app/data/questions.json` and redeploy backend
2. **Customize UI:** Modify templates in `app/templates/` and `frontend/`
3. **Enable authentication:** Add Flask-Login or AWS Cognito
4. **Setup HTTPS:** Use AWS Certificate Manager + ALB
5. **Monitor:** Enable CloudWatch alarms for EC2/DynamoDB
6. **Backup:** Enable DynamoDB point-in-time recovery

---

## 🆘 Troubleshooting

**Q: API returns 403 or DynamoDB error?**
- Check EC2 has internet access
- Verify IAM user has DynamoDB permissions (PutItem, Query, Scan)
- Confirm table names match in `.env`

**Q: S3 frontend not loading?**
- Clear browser cache
- Check S3 bucket policy allows public read
- Verify website configuration is enabled

**Q: Flask service won't start?**
- SSH to EC2 and check logs: `sudo journalctl -u quiz.service -n 50`
- Ensure dependencies installed: `pip3 list | grep Flask`

**Q: Can't SSH to EC2?**
- Verify security group allows port 22
- Check key pair is correct: `chmod 600 /tmp/quiz-deploy-key.pem`
- Verify instance is running: `aws ec2 describe-instances`

---

**Deployed:** January 2, 2026 | **Region:** ap-south-1 | **Status:** ✅ Live
