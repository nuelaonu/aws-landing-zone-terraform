variable "root_email_domain" {
  description = "Domain used to construct account email aliases. Example only - replace before use."
  type        = string
  default     = "example.com"
}

variable "allowed_regions" {
  description = "Regions workloads are allowed to operate in. All other regions are denied by SCP."
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
}

variable "accounts" {
  description = "Map of logical account name to account definition. Account creation is opt-in via create_accounts."
  type = map(object({
    email = string
    ou    = string # security | infrastructure | workloads | sandbox
  }))
  default = {}
}

variable "create_accounts" {
  description = "Whether to create accounts defined in var.accounts. False keeps this module plan-only for existing orgs."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied where supported."
  type        = map(string)
  default     = {}
}
