variable "aws_region" {
    description = "AWS region for resources"
    type        = string
    default     = "us-east-1"
  }

  variable "environment" {
    description = "Environment name (dev, staging, prod)"
    type        = string
    default     = "dev"
  }

  variable "project_name" {
    description = "Name of the project"
    type        = string
    default     = "rental-arbitrage"
  }

  variable "s3_bucket_prefix" {
    description = "Prefix for S3 bucket names (must be globally unique)"
    type        = string
  }
