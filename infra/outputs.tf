output "ec2_public_ip" {
  value       = aws_instance.quiz_ec2.public_ip
  description = "Public IP for accessing the quiz app at http://<ip>:5000"
}

output "dynamo_users_table" {
  value       = aws_dynamodb_table.users.name
  description = "Users table name"
}

output "dynamo_scores_table" {
  value       = aws_dynamodb_table.scores.name
  description = "Scores table name"
}
