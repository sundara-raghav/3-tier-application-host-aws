terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"] # Amazon Linux

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# IAM Role for EC2 to access DynamoDB
resource "aws_iam_role" "quiz_ec2_role" {
  name = "quiz-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Policy for DynamoDB access
resource "aws_iam_role_policy" "quiz_dynamodb_policy" {
  name = "quiz-dynamodb-policy"
  role = aws_iam_role.quiz_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Resource = [
        aws_dynamodb_table.users.arn,
        aws_dynamodb_table.scores.arn
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "quiz_ec2_profile" {
  name = "quiz-ec2-profile"
  role = aws_iam_role.quiz_ec2_role.name
}

resource "aws_security_group" "quiz_sg" {
  name        = "quiz-app-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask dev"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "quiz_ec2" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.ec2_instance_type
  iam_instance_profile        = aws_iam_instance_profile.quiz_ec2_profile.name
  vpc_security_group_ids      = [aws_security_group.quiz_sg.id]
  associate_public_ip_address = true
  key_name                    = "quiz-debug-key"
  subnet_id                   = element(data.aws_subnets.default.ids, 0)

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -x
              exec > >(tee /var/log/user-data.log)
              exec 2>&1
              
              yum update -y
              yum install -y python3 python3-pip git
              pip3 install --upgrade pip
              
              useradd -m quiz || true
              mkdir -p /opt/quiz-app
              chown -R quiz:quiz /opt/quiz-app
              
              # Clone from GitHub
              cd /tmp
              if git clone https://github.com/sundara-raghav/3-tier-application-host-aws.git app-source; then
                echo "Successfully cloned from GitHub"
                cp -r app-source/* /opt/quiz-app/
                cd /opt/quiz-app
              else
                echo "ERROR: Failed to clone from GitHub"
                exit 1
              fi
              
              cd /opt/quiz-app
              echo "Installing requirements..."
              pip3 install -q -r requirements.txt 2>&1 | tee -a /tmp/pip-install.log || {
                echo "pip3 install failed, trying manual install"
                pip3 install -q flask python-dotenv boto3 flask-cors
              }
              
              cat >/etc/systemd/system/quiz.service <<'SERVICE'
              [Unit]
              Description=Quiz Flask App
              After=network.target

              [Service]
              User=quiz
              WorkingDirectory=/opt/quiz-app
              Environment="FLASK_APP=run.py"
              Environment="AWS_REGION=ap-south-1"
              ExecStart=/usr/bin/python3 /opt/quiz-app/run.py
              Restart=always
              StandardOutput=journal
              StandardError=journal

              [Install]
              WantedBy=multi-user.target
              SERVICE

              systemctl daemon-reload
              systemctl enable quiz.service
              systemctl start quiz.service
              echo "Quiz service started"
              EOF
  )

  tags = {
    Name = "quiz-app"
  }
}

resource "aws_dynamodb_table" "users" {
  name         = var.dynamo_users_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "quiz_attempt_id"

  attribute {
    name = "quiz_attempt_id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "scores" {
  name         = var.dynamo_scores_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "topic"
  range_key    = "score_key"

  attribute {
    name = "topic"
    type = "S"
  }

  attribute {
    name = "score_key"
    type = "S"
  }
}
