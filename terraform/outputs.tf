output "s3_raw_data_bucket" {
  description = "Name of the S3 bucket for raw data"
  value       = aws_s3_bucket.raw_data.id
}

output "s3_processed_data_bucket" {
  description = "Name of the S3 bucket for processed data"
  value       = aws_s3_bucket.processed_data.id
}

output "airflow_execution_role_arn" {
  description = "ARN of the Airflow execution role"
  value       = aws_iam_role.airflow_execution_role.arn
}

output "ecr_airflow_repository_url" {
  description = "URL of the ECR repository for Airflow"
  value       = aws_ecr_repository.airflow_custom.repository_url
}

output "ecr_extractors_repository_url" {
  description = "URL of the ECR repository for data extractors"
  value       = aws_ecr_repository.data_extractors.repository_url
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the Airflow security group"
  value       = aws_security_group.airflow.id
}