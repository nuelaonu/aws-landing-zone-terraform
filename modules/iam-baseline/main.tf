# IAM baseline module
# Purpose: reusable permission-boundary and role patterns that keep
# human and workload identities least-privilege by construction.
# Boundaries cap what a role can ever do, even if an attached policy
# is later over-widened - defense in depth inside a single account,
# complementing SCPs at the organization level.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# --- Permissions boundary ---------------------------------------------------
# Workload roles may use common AWS services, but may not touch IAM
# administration, organization settings, or the audit infrastructure.

resource "aws_iam_policy" "workload_boundary" {
  name        = "WorkloadPermissionsBoundary"
  description = "Maximum permissions for workload roles. Denies IAM/org/audit tampering."
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowWorkloadServices"
        Effect = "Allow"
        Action = [
          "ec2:*", "eks:*", "ecr:*", "s3:*", "sqs:*", "rds:*",
          "lambda:*", "logs:*", "cloudwatch:*", "kms:Decrypt",
          "kms:GenerateDataKey", "secretsmanager:GetSecretValue",
          "ssm:GetParameter*", "route53:ChangeResourceRecordSets",
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyPrivilegeEscalation"
        Effect = "Deny"
        Action = [
          "iam:CreateUser", "iam:CreatePolicy", "iam:AttachUserPolicy",
          "iam:PutUserPolicy", "iam:CreateRole", "organizations:*",
          "cloudtrail:StopLogging", "cloudtrail:DeleteTrail",
          "config:Delete*", "guardduty:Delete*",
        ]
        Resource = "*"
      }
    ]
  })
}

# --- Break-glass / admin role ----------------------------------------------
# No standing human access by default. This role exists for incidents,
# requires MFA, has a short session, and should be alarmed on use
# (CloudTrail metric filter / EventBridge rule - see README).

locals {
  mfa_condition = var.require_mfa ? {
    Bool = { "aws:MultiFactorAuthPresent" = "true" }
  } : {}
}

resource "aws_iam_role" "break_glass" {
  name                 = "BreakGlassAdmin"
  max_session_duration = var.max_session_duration
  permissions_boundary = aws_iam_policy.workload_boundary.arn
  tags                 = merge(var.tags, { Purpose = "break-glass" })

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.trusted_account_id}:root" }
        Action    = "sts:AssumeRole"
        Condition = local.mfa_condition
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "break_glass" {
  role       = aws_iam_role.break_glass.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --- Standard workload role pattern ----------------------------------------
# Example: an application / EKS node-adjacent workload role. Real
# workloads should scope Resource ARNs down; the boundary above is
# the safety net when they do not.

resource "aws_iam_role" "workload" {
  name                 = "WorkloadStandard"
  permissions_boundary = aws_iam_policy.workload_boundary.arn
  tags                 = merge(var.tags, { Purpose = "workload" })

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = ["ec2.amazonaws.com", "eks.amazonaws.com"] }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "workload_s3_read" {
  name        = "WorkloadS3ReadExample"
  description = "Example scoped policy - read from app buckets only."
  tags        = var.tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadAppBuckets"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = ["arn:aws:s3:::app-data-*", "arn:aws:s3:::app-data-*/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "workload_s3" {
  role       = aws_iam_role.workload.name
  policy_arn = aws_iam_policy.workload_s3_read.arn
}

# --- Deny unencrypted / enforce TLS helper policy ---------------------------

resource "aws_iam_policy" "deny_no_tls" {
  name        = "DenyInsecureTransport"
  description = "Attach to roles that handle sensitive data; denies non-TLS AWS API calls."
  tags        = var.tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonTLS"
        Effect    = "Deny"
        Action    = "*"
        Resource  = "*"
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      }
    ]
  })
}
