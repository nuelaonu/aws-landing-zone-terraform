output "organization_id" {
  description = "ID of the AWS Organization."
  value       = aws_organizations_organization.this.id
}

output "organization_root_id" {
  description = "Root ID of the organization."
  value       = aws_organizations_organization.this.roots[0].id
}

output "ou_ids" {
  description = "Map of OU name to OU ID."
  value       = local.ou_ids
}

output "scp_ids" {
  description = "Map of SCP name to policy ID."
  value = {
    deny_leave_org     = aws_organizations_policy.deny_leave_org.id
    protect_audit      = aws_organizations_policy.protect_audit.id
    restrict_regions   = aws_organizations_policy.restrict_regions.id
    require_encryption = aws_organizations_policy.require_encryption.id
  }
}

output "account_ids" {
  description = "Map of created account name to account ID (empty when create_accounts is false)."
  value       = { for k, v in aws_organizations_account.this : k => v.id }
}
