
output "s3_bucket_name" {
  description = "Fraud detection S3 bucket name"
  value       = aws_s3_bucket.fraud_detection_data.id
}

output "s3_bucket_arn" {
  description = "Fraud detection S3 bucket ARN"
  value       = aws_s3_bucket.fraud_detection_data.arn
}

output "s3_bucket_region" {
  description = "S3 bucket AWS region"
  value       = aws_s3_bucket.fraud_detection_data.region
}

output "s3_bucket_endpoint" {
  description = "S3 bucket endpoint"
  value       = "https://${aws_s3_bucket.fraud_detection_data.bucket}.s3.${aws_s3_bucket.fraud_detection_data.region}.amazonaws.com"
}
