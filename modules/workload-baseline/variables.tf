variable "name" {
  description = "Workload name, used as a prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from the networking module."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs from the networking module."
  type        = list(string)
}

variable "data_subnet_ids" {
  description = "Data subnet IDs from the networking module."
  type        = list(string)
  default     = []
}

variable "monthly_budget_limit" {
  description = "Monthly budget in USD for this workload account."
  type        = number
  default     = 500
}

variable "budget_alert_emails" {
  description = "Emails notified on budget thresholds."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to resources. CostCenter and Environment drive cost allocation."
  type        = map(string)
  default     = {}
}
