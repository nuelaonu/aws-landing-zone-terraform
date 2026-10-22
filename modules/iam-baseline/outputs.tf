output "permissions_boundary_arn" {
  description = "ARN of the workload permissions boundary policy."
  value       = aws_iam_policy.workload_boundary.arn
}

output "break_glass_role_arn" {
  description = "ARN of the break-glass admin role."
  value       = aws_iam_role.break_glass.arn
}

output "workload_role_arn" {
  description = "ARN of the standard workload role."
  value       = aws_iam_role.workload.arn
}

output "deny_no_tls_policy_arn" {
  description = "ARN of the deny-non-TLS policy."
  value       = aws_iam_policy.deny_no_tls.arn
}
