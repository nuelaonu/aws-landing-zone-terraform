output "budget_name" {
  description = "Monthly budget name."
  value       = aws_budgets_budget.monthly.name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for cost alerts - subscribe automation (Lambda, Slack bridges) here."
  value       = aws_sns_topic.cost_alerts.arn
}

output "cur_bucket_name" {
  description = "CUR bucket name, if created."
  value       = try(aws_s3_bucket.cur[0].id, null)
}

output "required_tag_keys" {
  description = "Tag keys expected for cost allocation."
  value       = var.required_tags
}
