variable "monthly_limit_usd" {
  description = "Organization / account monthly cost limit in USD."
  type        = number
  default     = 2000
}

variable "alert_emails" {
  description = "Email subscribers for budget alerts (also subscribed to the SNS topic)."
  type        = list(string)
  default     = []
}

variable "cur_bucket_name" {
  description = "Bucket name for Cost and Usage Reports. Empty string skips CUR resources."
  type        = string
  default     = ""
}

variable "required_tags" {
  description = "Tag keys expected on cost-bearing resources, for allocation reporting."
  type        = list(string)
  default     = ["CostCenter", "Environment", "Owner", "Project"]
}

variable "tags" {
  description = "Tags applied to resources."
  type        = map(string)
  default     = {}
}
