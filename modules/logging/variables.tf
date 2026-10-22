variable "log_bucket_name" {
  description = "Globally unique name for the centralized log archive bucket."
  type        = string
}

variable "organization_id" {
  description = "AWS Organization ID, used in bucket and trail policies."
  type        = string
}

variable "retention_days" {
  description = "Lifecycle retention for log objects before transition / expiration."
  type        = number
  default     = 365
}

variable "member_account_ids" {
  description = "Account IDs the Config aggregator should collect from."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to resources."
  type        = map(string)
  default     = {}
}
