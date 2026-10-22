output "kms_key_arn" {
  description = "ARN of the workload default EBS encryption key."
  value       = aws_kms_key.workload.arn
}

output "db_subnet_group_name" {
  description = "DB subnet group name, if data subnets were supplied."
  value       = try(aws_db_subnet_group.this[0].name, null)
}

output "workload_security_group_id" {
  description = "Baseline workload security group ID."
  value       = aws_security_group.workload.id
}

output "config_recorder_name" {
  description = "Config recorder name."
  value       = aws_config_configuration_recorder.this.name
}

output "budget_name" {
  description = "Workload budget name, if alerts were configured."
  value       = try(aws_budgets_budget.workload[0].name, null)
}
