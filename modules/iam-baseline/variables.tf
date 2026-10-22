variable "trusted_account_id" {
  description = "Account ID allowed to assume baseline roles (typically the management or security account)."
  type        = string
}

variable "require_mfa" {
  description = "Require MFA for human / break-glass role assumption."
  type        = bool
  default     = true
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds for the admin role."
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Tags applied to resources."
  type        = map(string)
  default     = {}
}
