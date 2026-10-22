output "ou_ids" {
  description = "OU IDs from the organization module."
  value       = module.organization.ou_ids
}

output "eks_subnet_ids" {
  description = "Private subnets ready for EKS consumption."
  value       = module.networking.private_subnet_ids
}

output "log_bucket_arn" {
  description = "Central log bucket ARN."
  value       = module.logging.log_bucket_arn
}

output "cost_alert_topic_arn" {
  description = "Cost alert SNS topic ARN."
  value       = module.cost_guardrails.sns_topic_arn
}

output "workload_boundary_arn" {
  description = "Workload permissions boundary ARN."
  value       = module.iam_baseline.permissions_boundary_arn
}
