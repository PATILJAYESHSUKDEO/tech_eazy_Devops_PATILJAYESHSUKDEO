output "bucket_name" {
  description = "The S3 bucket used for logs"
  value       = aws_s3_bucket.logs_bucket.id
}

output "readonly_role_arn" {
  description = "ARN of the read-only IAM role"
  value       = aws_iam_role.readonly_role.arn
}

output "writeonly_role_name" {
  description = "Name of the write-only IAM role"
  value       = aws_iam_role.writeonly_role.name
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_instance.id
}
