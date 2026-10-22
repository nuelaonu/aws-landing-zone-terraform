# Organization module
# Purpose: create / describe the AWS Organization, OU structure, and
# Service Control Policies (SCPs) that form the outer guardrails for
# every account. SCPs are maximum-permission boundaries - they never
# grant access by themselves, they only limit what IAM can grant.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_organizations_organization" "this" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com",
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
  ]

  feature_set = "ALL"
}

# --- Organizational Units -------------------------------------------------

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.this.roots[0].id
  tags      = var.tags
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infrastructure"
  parent_id = aws_organizations_organization.this.roots[0].id
  tags      = var.tags
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.this.roots[0].id
  tags      = var.tags
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = aws_organizations_organization.this.roots[0].id
  tags      = var.tags
}

locals {
  ou_ids = {
    security       = aws_organizations_organizational_unit.security.id
    infrastructure = aws_organizations_organizational_unit.infrastructure.id
    workloads      = aws_organizations_organizational_unit.workloads.id
    sandbox        = aws_organizations_organizational_unit.sandbox.id
  }
}

# --- Accounts (opt-in) ----------------------------------------------------
# Account creation is slow, effectively irreversible, and email-bound.
# Keeping it behind a flag lets reviewers plan the guardrails without
# accidentally provisioning accounts.

resource "aws_organizations_account" "this" {
  for_each = var.create_accounts ? var.accounts : {}

  name                       = each.key
  email                      = each.value.email
  parent_id                  = local.ou_ids[each.value.ou]
  iam_user_access_to_billing = "DENY"
  tags                       = var.tags

  lifecycle {
    ignore_changes = [email, iam_user_access_to_billing]
  }
}

# --- SCP: deny leaving the organization -----------------------------------

resource "aws_organizations_policy" "deny_leave_org" {
  name        = "DenyLeaveOrganization"
  description = "Prevent any account from leaving the organization."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyLeaveOrganization"
        Effect   = "Deny"
        Action   = ["organizations:LeaveOrganization"]
        Resource = "*"
      }
    ]
  })
}

# --- SCP: protect audit trails --------------------------------------------

resource "aws_organizations_policy" "protect_audit" {
  name        = "ProtectAuditTrails"
  description = "Deny disabling or deleting CloudTrail, Config, and GuardDuty."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyDisableAuditServices"
        Effect = "Deny"
        Action = [
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail",
          "cloudtrail:UpdateTrail",
          "config:DeleteConfigurationRecorder",
          "config:StopConfigurationRecorder",
          "guardduty:DeleteDetector",
          "guardduty:DisassociateFromMasterAccount",
        ]
        Resource = "*"
      }
    ]
  })
}

# --- SCP: region restriction ----------------------------------------------
# Identity and global services are allow-listed explicitly; without
# those exceptions this policy would break IAM, Organizations, and STS
# global endpoints. This is the most commonly broken SCP in practice.

resource "aws_organizations_policy" "restrict_regions" {
  name        = "RestrictToApprovedRegions"
  description = "Deny regional actions outside the approved region list."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyNonApprovedRegions"
        Effect = "Deny"
        NotAction = [
          "iam:*",
          "organizations:*",
          "route53:*",
          "cloudfront:*",
          "sts:*",
          "support:*",
          "budgets:*",
          "ce:*",
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = var.allowed_regions
          }
        }
      }
    ]
  })
}

# --- SCP: require encryption at rest for new volumes / objects -------------

resource "aws_organizations_policy" "require_encryption" {
  name        = "RequireEncryption"
  description = "Deny unencrypted EBS volume creation and S3 puts without SSE."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyUnencryptedEBS"
        Effect   = "Deny"
        Action   = ["ec2:CreateVolume"]
        Resource = "*"
        Condition = {
          Bool = { "ec2:Encrypted" = "false" }
        }
      },
      {
        Sid      = "DenyUnencryptedS3Put"
        Effect   = "Deny"
        Action   = ["s3:PutObject"]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = ["aws:kms", "AES256"]
          }
          Null = { "s3:x-amz-server-side-encryption" = "false" }
        }
      }
    ]
  })
}

# --- SCP attachments --------------------------------------------------------
# Baseline SCPs attach to every OU. The region policy is intentionally
# NOT attached to Sandbox in this reference - sandbox experimentation
# is a deliberate, documented tradeoff, called out in the README.
# In a stricter environment, attach it there as well.

resource "aws_organizations_policy_attachment" "deny_leave_all" {
  for_each  = local.ou_ids
  policy_id = aws_organizations_policy.deny_leave_org.id
  target_id = each.value
}

resource "aws_organizations_policy_attachment" "protect_audit_all" {
  for_each  = local.ou_ids
  policy_id = aws_organizations_policy.protect_audit.id
  target_id = each.value
}

resource "aws_organizations_policy_attachment" "encryption_all" {
  for_each  = local.ou_ids
  policy_id = aws_organizations_policy.require_encryption.id
  target_id = each.value
}

resource "aws_organizations_policy_attachment" "regions_restricted" {
  for_each = {
    security       = local.ou_ids.security
    infrastructure = local.ou_ids.infrastructure
    workloads      = local.ou_ids.workloads
  }
  policy_id = aws_organizations_policy.restrict_regions.id
  target_id = each.value
}
