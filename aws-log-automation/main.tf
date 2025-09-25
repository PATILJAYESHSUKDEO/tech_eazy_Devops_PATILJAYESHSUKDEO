terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Validation: Ensure bucket name is provided
locals {
  bucket_name_trimmed = trim(var.bucket_name)
}

resource "null_resource" "validate_bucket_name" {
  provisioner "local-exec" {
    command = "if [ -z '${local.bucket_name_trimmed}' ]; then echo 'Error: bucket_name must be provided!' >&2 ; exit 1; fi"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "logs_bucket" {
  bucket = var.bucket_name
  acl    = "private"

  lifecycle_rule {
    id      = "delete-logs-after-7-days"
    enabled = true
    prefix  = "logs/"
    expiration {
      days = 7
    }
  }

  force_destroy = false
}

# Read-only Role
resource "aws_iam_role" "readonly_role" {
  name = "readonly-s3-role"
  assume_role_policy = jsonencode({
    Versi
