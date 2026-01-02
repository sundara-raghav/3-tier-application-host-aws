variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "ec2_instance_type" {
  description = "EC2 instance size for Flask app"
  type        = string
  default     = "t3.micro"
}

variable "ec2_key_name" {
  description = "Existing EC2 key pair name for SSH access"
  type        = string
}

variable "dynamo_users_table" {
  description = "DynamoDB table for quiz attempts"
  type        = string
  default     = "quiz_users"
}

variable "dynamo_scores_table" {
  description = "DynamoDB table for leaderboard"
  type        = string
  default     = "quiz_scores"
}
