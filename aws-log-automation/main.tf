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
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "readonly_s3_policy" {
  name = "readonly-s3-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:ListBucket"],
        Resource = ["arn:aws:s3:::${var.bucket_name}"]
      },
      {
        Effect = "Allow",
        Action = ["s3:GetObject"],
        Resource = ["arn:aws:s3:::${var.bucket_name}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_readonly_policy" {
  role       = aws_iam_role.readonly_role.name
  policy_arn = aws_iam_policy.readonly_s3_policy.arn
}

# Write-only Role
resource "aws_iam_role" "writeonly_role" {
  name = "writeonly-s3-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "writeonly_s3_policy" {
  name = "writeonly-s3-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = ["arn:aws:s3:::${var.bucket_name}/*"]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:CreateBucket"
        ],
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_writeonly_policy" {
  role       = aws_iam_role.writeonly_role.name
  policy_arn = aws_iam_policy.writeonly_s3_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.writeonly_role.name
}

# EC2 Instance
resource "aws_instance" "app_instance" {
  ami                    = "ami-0c94855ba95c71c99"  # Amazon Linux 2 (us-east-1)
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  user_data              = templatefile("${path.module}/user_data.sh.tpl", { bucket_name = var.bucket_name })

  tags = {
    Name = "LogUploaderInstance"
  }
}
