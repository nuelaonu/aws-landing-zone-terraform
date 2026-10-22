output "log_bucket_arn" {
  description = "ARN of the centralized log bucket."
  value       = aws_s3_bucket.logs.arn
}

output "log_bucket_name" {
  description = "Name of the centralized log bucket."
  value       = aws_s3_bucket.logs.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key encrypting logs."
  value       = aws_kms_key.logs.arn
}

output "cloudtrail_arn" {
  description = "ARN of the organization trail."
  value       = aws_cloudtrail.org.arn
}

output "config_aggregator_arn" {
  description = "ARN of the Config organization aggregator."
  value       = aws_config_configuration_aggregator.org.arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID in the delegated admin account."
  value       = aws_guardduty_detector.this.id
}
