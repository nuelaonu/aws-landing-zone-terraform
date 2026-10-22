variable "aws_region" {
  description = "Primary region for the example."
  type        = string
  default     = "us-east-1"
}

variable "log_bucket_name" {
  description = "Example log bucket name - must be globally unique if actually applied."
  type        = string
  default     = "example-org-log-archive-111122223333"
}

variable "cur_bucket_name" {
  description = "Example CUR bucket name."
  type        = string
  default     = "example-org-cur-111122223333"
}
