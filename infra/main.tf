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

# IAM removed - no S3 access needed

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
  vpc_security_group_ids      = [aws_security_group.quiz_sg.id]
  associate_public_ip_address = true
  key_name                    = var.ec2_key_name
  subnet_id                   = element(data.aws_subnets.default.ids, 0)

  user_data = <<-EOF
              #!/bin/bash
              set -e
              yum update -y
              yum install -y python3 git
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
              pip3 install -q -r requirements.txt 2>/dev/null || pip3 install -q flask python-dotenv boto3 flask-cors
              
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

              [Install]
              WantedBy=multi-user.target
              SERVICE

              systemctl daemon-reload
              systemctl enable quiz.service
              systemctl start quiz.service
              EOF

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

# S3 removed - app is self-contained on EC2
