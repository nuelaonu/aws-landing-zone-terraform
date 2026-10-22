# Complete example - composes every module with obviously fake values.
# Account IDs are the AWS documentation-style example IDs, emails use
# example.com, and no real identifier appears anywhere in this file.
#
# Apply order in a real org (state is split per account in practice):
#   1. organization  (management account)
#   2. logging       (log archive account, aliased provider)
#   3. networking + workload-baseline + iam-baseline (workload account)
#   4. cost-guardrails (management / payer account, us-east-1 for CUR)
# This single-root composition is for reading and `terraform validate`,
# not a recommendation to hold all accounts in one state file.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  tags = {
    Environment = "example"
    CostCenter  = "platform"
    Owner       = "platform-team"
    Project     = "landing-zone"
    ManagedBy   = "terraform"
  }

  # Fake account IDs - for shape only.
  security_account_id       = "111122223333"
  log_archive_account_id    = "222233334444"
  infrastructure_account_id = "333344445555"
  workload_account_id       = "444455556666"
}

module "organization" {
  source = "../../modules/organization"

  allowed_regions   = ["us-east-1", "us-west-2"]
  create_accounts   = false
  root_email_domain = "example.com"

  accounts = {
    security       = { email = "aws+security@example.com", ou = "security" }
    log-archive    = { email = "aws+logs@example.com", ou = "security" }
    infrastructure = { email = "aws+infra@example.com", ou = "infrastructure" }
    workload-prod  = { email = "aws+workload-prod@example.com", ou = "workloads" }
    sandbox        = { email = "aws+sandbox@example.com", ou = "sandbox" }
  }

  tags = local.tags
}

module "logging" {
  source = "../../modules/logging"

  log_bucket_name    = var.log_bucket_name
  organization_id    = "o-example12345"
  retention_days     = 365
  member_account_ids = [local.workload_account_id, local.infrastructure_account_id]
  tags               = local.tags
}

module "iam_baseline" {
  source = "../../modules/iam-baseline"

  trusted_account_id   = local.security_account_id
  require_mfa          = true
  max_session_duration = 3600
  tags                 = local.tags
}

module "networking" {
  source = "../../modules/networking"

  name               = "shared"
  cidr_block         = "10.20.0.0/16"
  azs                = ["us-east-1a", "us-east-1b", "us-east-1c"]
  log_bucket_arn     = module.logging.log_bucket_arn
  single_nat_gateway = false
  tags               = local.tags
}

module "workload_baseline" {
  source = "../../modules/workload-baseline"

  name                 = "workload-prod"
  vpc_id               = module.networking.vpc_id
  private_subnet_ids   = module.networking.private_subnet_ids
  data_subnet_ids      = module.networking.data_subnet_ids
  monthly_budget_limit = 500
  budget_alert_emails  = ["aws+workload-prod@example.com"]
  tags                 = local.tags
}

module "cost_guardrails" {
  source = "../../modules/cost-guardrails"

  monthly_limit_usd = 2000
  alert_emails      = ["aws+alerts@example.com"]
  cur_bucket_name   = var.cur_bucket_name
  tags              = local.tags
}
