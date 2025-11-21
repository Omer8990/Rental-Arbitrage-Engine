  terraform {
    required_version = ">= 1.0"

    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
      }
    }
  }

  provider "aws" {
    region = var.aws_region

    default_tags {
      tags = {
        Project     = "rental-arbitrage-engine"
        Environment = var.environment
        ManagedBy   = "terraform"
      }
    }
  }

  # S3 bucket for raw data storage
  resource "aws_s3_bucket" "raw_data" {
    bucket = "${var.s3_bucket_prefix}-raw-data"
  }

  resource "aws_s3_bucket_versioning" "raw_data_versioning" {
    bucket = aws_s3_bucket.raw_data.id
    versioning_configuration {
      status = "Enabled"
    }
  }

  resource "aws_s3_bucket_server_side_encryption_configuration" "raw_data_encryption" {
    bucket = aws_s3_bucket.raw_data.id

    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  # S3 bucket for processed data storage
  resource "aws_s3_bucket" "processed_data" {
    bucket = "${var.s3_bucket_prefix}-processed-data"
  }

  resource "aws_s3_bucket_versioning" "processed_data_versioning" {
    bucket = aws_s3_bucket.processed_data.id
    versioning_configuration {
      status = "Enabled"
    }
  }

  resource "aws_s3_bucket_server_side_encryption_configuration" "processed_data_encryption" {
    bucket = aws_s3_bucket.processed_data.id

    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  # IAM role for Airflow tasks
  resource "aws_iam_role" "airflow_execution_role" {
    name = "${var.project_name}-airflow-execution-role"

    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        }
      ]
    })
  }

  # IAM policy for S3 access
  resource "aws_iam_role_policy" "airflow_s3_policy" {
    name = "${var.project_name}-airflow-s3-policy"
    role = aws_iam_role.airflow_execution_role.id

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:ListBucket"
          ]
          Resource = [
            aws_s3_bucket.raw_data.arn,
            "${aws_s3_bucket.raw_data.arn}/*",
            aws_s3_bucket.processed_data.arn,
            "${aws_s3_bucket.processed_data.arn}/*"
          ]
        }
      ]
    })
  }

  # ECR repository for custom Docker images
  resource "aws_ecr_repository" "airflow_custom" {
    name                 = "${var.project_name}-airflow"
    image_tag_mutability = "MUTABLE"

    image_scanning_configuration {
      scan_on_push = true
    }
  }

  # ECR repository for Python extraction scripts
  resource "aws_ecr_repository" "data_extractors" {
    name                 = "${var.project_name}-extractors"
    image_tag_mutability = "MUTABLE"

    image_scanning_configuration {
      scan_on_push = true
    }
  }

  # VPC for EC2 instances
  resource "aws_vpc" "main" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = {
      Name = "${var.project_name}-vpc"
    }
  }

  # Internet Gateway
  resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
      Name = "${var.project_name}-igw"
    }
  }

  # Public subnet
  resource "aws_subnet" "public" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "${var.aws_region}a"
    map_public_ip_on_launch = true

    tags = {
      Name = "${var.project_name}-public-subnet"
    }
  }

  # Route table for public subnet
  resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.main.id
    }

    tags = {
      Name = "${var.project_name}-public-rt"
    }
  }

  resource "aws_route_table_association" "public" {
    subnet_id      = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
  }

  # Security group for EC2 instances
  resource "aws_security_group" "airflow" {
    name        = "${var.project_name}-airflow-sg"
    description = "Security group for Airflow EC2 instances"
    vpc_id      = aws_vpc.main.id

    ingress {
      description = "HTTP"
      from_port   = 8080
      to_port     = 8080
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

    tags = {
      Name = "${var.project_name}-airflow-sg"
    }
  }
