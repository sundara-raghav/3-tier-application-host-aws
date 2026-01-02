# 🎯 Quiz Web Application - AWS Cloud Deployment

A modern, responsive quiz application built with Python Flask and deployed on AWS infrastructure. Features multiple quiz topics, real-time scoring, and a global leaderboard.

## �� Table of Contents
- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [AWS Deployment](#aws-deployment)
- [API Endpoints](#api-endpoints)
- [Project Structure](#project-structure)

## ✨ Features

- **10 Quiz Topics**: Python, AWS, DevOps, JavaScript, React, Docker, Git, Linux, Database, Security
- **20 Questions per Topic**: Comprehensive question bank with 200 total questions
- **15-Minute Timer**: Countdown timer with visual warnings and auto-submit
- **Real-time Scoring**: Instant feedback on quiz completion
- **Global Leaderboard**: View top scores filtered by topic
- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile devices
- **Clean UI**: Modern dark theme with smooth animations and hover effects

## ��️ Architecture

```
┌─────────────────┐
│   User Browser  │
└────────┬────────┘
         │ HTTP
         ▼
┌─────────────────┐
│   EC2 Instance  │
│  Flask App      │
│  Port 5000      │
└────────┬────────┘
         │ Boto3
         ▼
┌─────────────────┐
│   DynamoDB      │
│  - quiz_users   │
│  - quiz_scores  │
└─────────────────┘
```

### Components:
- **Frontend**: HTML templates with responsive CSS (served by Flask)
- **Backend**: Python Flask REST API
- **Database**: AWS DynamoDB for user attempts and scores
- **Infrastructure**: AWS EC2 (t3.micro) provisioned via Terraform

## 🛠️ Tech Stack

### Backend
- **Python 3.9+**
- **Flask** - Web framework
- **Flask-CORS** - Cross-origin resource sharing
- **Boto3** - AWS SDK for Python
- **python-dotenv** - Environment variable management

### Frontend
- **HTML5**
- **CSS3** (Responsive design with media queries)
- **Vanilla JavaScript** (Timer, form handling)

### Infrastructure
- **AWS EC2** - Application hosting
- **AWS DynamoDB** - NoSQL database
- **Terraform** - Infrastructure as Code
- **Systemd** - Service management on EC2

### Development
- **GitHub Codespaces** - Cloud development environment
- **Git** - Version control

## 📦 Prerequisites

### For Local Development:
- Python 3.9 or higher
- pip (Python package manager)
- AWS CLI configured with credentials
- Git

### For AWS Deployment:
- AWS Account with appropriate permissions
- Terraform installed (v1.0+)
- EC2 Key Pair in your AWS region
- AWS credentials configured (\`AWS_ACCESS_KEY_ID\`, \`AWS_SECRET_ACCESS_KEY\`)

## 💻 Local Development

### 1. Clone the Repository
\`\`\`bash
git clone https://github.com/sundara-raghav/3-tier-application-host-aws.git
cd 3-tier-application-host-aws
\`\`\`

### 2. Create Virtual Environment
\`\`\`bash
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
\`\`\`

### 3. Install Dependencies
\`\`\`bash
pip install -r requirements.txt
\`\`\`

### 4. Configure Environment Variables
Create a \`.env\` file in the root directory:
\`\`\`bash
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=ap-south-1
DYNAMO_USERS_TABLE=quiz_users
DYNAMO_SCORES_TABLE=quiz_scores
\`\`\`

### 5. Run the Application
\`\`\`bash
python run.py
\`\`\`

Access the app at: \`http://localhost:5000\`

## ☁️ AWS Deployment

### Step 1: Configure AWS Credentials
\`\`\`bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_REGION=ap-south-1
\`\`\`

### Step 2: Initialize Terraform
\`\`\`bash
cd infra
terraform init
\`\`\`

### Step 3: Review the Plan
\`\`\`bash
terraform plan
\`\`\`

### Step 4: Deploy Infrastructure
\`\`\`bash
terraform apply
\`\`\`

Terraform will create:
- ✅ EC2 instance (t3.micro) with Flask app auto-deployed
- ✅ Security Group (allows ports 22, 80, 5000)
- ✅ DynamoDB tables (quiz_users, quiz_scores)
- ✅ IAM role with DynamoDB permissions

### Step 5: Access Your Application
After deployment completes, Terraform will output:
\`\`\`
ec2_public_ip = "13.202.245.5"
\`\`\`

Access your app at: \`http://<EC2_PUBLIC_IP>:5000\`

### Step 6: Verify Deployment
\`\`\`bash
# Check if Flask is running
curl http://<EC2_PUBLIC_IP>:5000/health

# Test quiz topics endpoint
curl http://<EC2_PUBLIC_IP>:5000/quiz/python?format=json
\`\`\`

## 🔌 API Endpoints

### Health Check
\`\`\`http
GET /health
\`\`\`
Returns server status and number of topics loaded.

### Home Page
\`\`\`http
GET /
\`\`\`
Renders the main quiz selection page.

### Get Quiz Questions
\`\`\`http
GET /quiz/<topic>?format=json
\`\`\`
**Parameters:**
- \`topic\` - Quiz topic (python, aws, devops, javascript, react, docker, git, linux, database, security)
- \`format\` - Optional: \`json\` for API response

**Response:**
\`\`\`json
{
  "topic": "python",
  "questions": [
    {
      "id": "py1",
      "question": "What does PEP stand for?",
      "options": ["Python Enhancement Proposal", "Programming Engineering Plan", "..."],
      "answer": "Python Enhancement Proposal"
    }
  ]
}
\`\`\`

### Submit Quiz
\`\`\`http
POST /submit
Content-Type: application/json

{
  "username": "John Doe",
  "topic": "python",
  "answers": {
    "py1": "Python Enhancement Proposal",
    "py2": "except",
    ...
  }
}
\`\`\`

**Response:**
\`\`\`json
{
  "score": 15,
  "total": 20,
  "username": "John Doe",
  "topic": "python",
  "quiz_attempt_id": "abc123..."
}
\`\`\`

### View Scoreboard
\`\`\`http
GET /scoreboard?topic=python&format=json
\`\`\`
**Parameters:**
- \`topic\` - Optional: filter by topic
- \`format\` - Optional: \`json\` for API response

**Response:**
\`\`\`json
{
  "scores": [
    {
      "username": "John Doe",
      "topic": "python",
      "score": "15",
      "total": "20",
      "timestamp": "1767371640"
    }
  ],
  "topics": ["python", "aws", "devops", ...],
  "selected_topic": "python"
}
\`\`\`

## 📁 Project Structure

\`\`\`
3-tier-application-host-aws/
├── app/
│   ├── __init__.py           # Flask app factory
│   ├── routes.py             # API endpoints
│   ├── services/
│   │   └── dynamo.py         # DynamoDB service layer
│   ├── data/
│   │   └── questions.json    # Quiz questions (10 topics × 20 questions)
│   ├── templates/
│   │   ├── base.html         # Base template
│   │   ├── index.html        # Home page
│   │   ├── quiz.html         # Quiz page
│   │   ├── result.html       # Results page
│   │   └── scoreboard.html   # Leaderboard page
│   └── static/
│       └── css/
│           └── styles.css    # Responsive styles
├── infra/
│   ├── main.tf               # Terraform main configuration
│   ├── variables.tf          # Input variables
│   ├── outputs.tf            # Output values
│   └── terraform.tfvars      # Variable values
├── run.py                    # Application entry point
├── requirements.txt          # Python dependencies
├── .gitignore                # Git ignore rules
└── README.md                 # This file
\`\`\`

## 🎨 UI Features

### Desktop View
- Full-width layout with optimized spacing
- Large, clickable quiz option cards
- Detailed scoreboard with all columns

### Tablet View (≤768px)
- Flexible layouts
- Adjusted padding and font sizes
- "When" column hidden in scoreboard

### Mobile View (≤480px)
- Ultra-compact padding
- Smaller fonts for readability
- Full-width forms
- Simplified scoreboard (rank, user, score)

### Quiz Options
- Smooth hover animations (4px slide effect)
- Color-coded selection feedback (cyan borders)
- Large touch targets (20px radio buttons)
- Semi-transparent backgrounds for depth

### Timer
- 15-minute countdown (900 seconds)
- Visual warning at 60 seconds (red background + pulse animation)
- Auto-submit when time expires
- Sticky positioning for visibility

## 🔐 Security Considerations

- AWS credentials stored in environment variables (never committed)
- Security group restricts access to required ports only (22, 80, 5000)
- IAM role follows principle of least privilege (DynamoDB read/write only)
- Input validation on all API endpoints
- CORS configured for cross-origin requests

## 🚀 Service Management

The EC2 instance runs Flask as a systemd service that:
- Automatically starts on boot
- Restarts on failure
- Logs to systemd journal

### View Logs
\`\`\`bash
ssh -i your-key.pem ec2-user@<EC2_IP>
sudo journalctl -u quiz.service -f
\`\`\`

### Restart Service
\`\`\`bash
sudo systemctl restart quiz.service
\`\`\`

### Check Status
\`\`\`bash
sudo systemctl status quiz.service
\`\`\`

## 🧪 Testing

### Manual Testing
1. Navigate to \`http://<EC2_IP>:5000\`
2. Enter your name
3. Select a topic from the dropdown
4. Click "Start Quiz"
5. Answer all 20 questions within 15 minutes
6. Submit and view your score
7. Check the leaderboard

### API Testing
\`\`\`bash
# Health check
curl http://<EC2_IP>:5000/health

# Get Python quiz questions
curl "http://<EC2_IP>:5000/quiz/python?format=json" | jq .

# Submit answers (example)
curl -X POST "http://<EC2_IP>:5000/submit" \\
  -H "Content-Type: application/json" \\
  -d '{
    "username": "TestUser",
    "topic": "python",
    "answers": {
      "py1": "Python Enhancement Proposal",
      "py2": "except"
    }
  }' | jq .

# View scoreboard
curl "http://<EC2_IP>:5000/scoreboard?format=json" | jq .
\`\`\`

## 🛠️ Troubleshooting

### Flask Not Starting
\`\`\`bash
# SSH into EC2
ssh -i your-key.pem ec2-user@<EC2_IP>

# Check service status
sudo systemctl status quiz.service

# View recent logs
sudo journalctl -u quiz.service -n 50

# Check if port 5000 is listening
sudo ss -tlnp | grep 5000
\`\`\`

### DynamoDB Connection Issues
- Verify IAM role is attached to EC2 instance
- Check security group allows outbound HTTPS (443)
- Ensure DynamoDB tables exist in the correct region
- Verify IAM role has correct permissions

### Questions Not Loading
\`\`\`bash
# Verify questions file exists
ls -la /opt/quiz-app/app/data/questions.json

# Check file contents
cat /opt/quiz-app/app/data/questions.json | jq 'keys'

# Should show: ["aws", "database", "devops", "docker", "git", "javascript", "linux", "python", "react", "security"]
\`\`\`

## 📊 DynamoDB Schema

### quiz_users Table
\`\`\`
Partition Key: quiz_attempt_id (String)
Attributes:
  - username (String)
  - topic (String)
  - score (Number)
  - total (Number)
  - timestamp (Number)
\`\`\`

### quiz_scores Table
\`\`\`
Partition Key: topic (String)
Sort Key: score_key (String)  # Format: "0015#1767371640#uuid"
Attributes:
  - username (String)
  - score (String)
  - total (String)
  - timestamp (String)
\`\`\`

The sort key format ensures scores are sorted in descending order (padded with zeros).

## 📝 Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| \`AWS_REGION\` | AWS region for DynamoDB | \`ap-south-1\` |
| \`DYNAMO_USERS_TABLE\` | DynamoDB table for user attempts | \`quiz_users\` |
| \`DYNAMO_SCORES_TABLE\` | DynamoDB table for scoreboard | \`quiz_scores\` |
| \`SECRET_KEY\` | Flask secret key for sessions | \`your-secret-key\` |

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch (\`git checkout -b feature/amazing-feature\`)
3. Commit your changes (\`git commit -m 'Add amazing feature'\`)
4. Push to the branch (\`git push origin feature/amazing-feature\`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👤 Author

**Sundara Raghav**
- GitHub: [@sundara-raghav](https://github.com/sundara-raghav)
- Repository: [3-tier-application-host-aws](https://github.com/sundara-raghav/3-tier-application-host-aws)

## 🙏 Acknowledgments

- Flask documentation and community
- AWS documentation
- Terraform AWS provider documentation
- GitHub Codespaces for development environment

---

**Live Demo**: http://13.202.245.5:5000/ 🚀

**Last Updated**: January 2, 2026
