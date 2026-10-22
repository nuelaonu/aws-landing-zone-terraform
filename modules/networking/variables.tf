variable "name" {
  description = "Name prefix for VPC resources."
  type        = string
  default     = "shared"
}

variable "cidr_block" {
  description = "VPC CIDR. /16 leaves room for three tiers across three AZs."
  type        = string
  default     = "10.20.0.0/16"
}

variable "azs" {
  description = "Availability zones to span. Exactly three expected by the subnet math."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "log_bucket_arn" {
  description = "Central log bucket ARN for VPC Flow Logs. Empty string disables flow logs."
  type        = string
  default     = ""
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway (cheaper, less resilient). False = one per AZ (production default)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to resources."
  type        = map(string)
  default     = {}
}
