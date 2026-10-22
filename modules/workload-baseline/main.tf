# Workload baseline module
# Purpose: the account-level floor every workload account gets before
# any application lands - encryption defaults, IMDSv2 posture, a Config
# recorder, a DB subnet group from the data tier, and a budget hookup
# so cost is visible from day one, not discovered at month end.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# --- EBS encryption by default (account-level setting) ---------------------

resource "aws_ebs_encryption_by_default" "this" {
  enabled = true
}

resource "aws_ebs_default_kms_key" "this" {
  key_id = aws_kms_key.workload.id
}

resource "aws_kms_key" "workload" {
  description             = "Default encryption for EBS volumes in this workload account"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = var.tags
}

# --- IMDSv2 enforcement ------------------------------------------------------
# The account-level default for new EC2 launches. Existing instances
# still need instance-level metadata_options; the Ansible baseline in
# this repo covers the host side, and the SCP module covers org intent.

resource "aws_ec2_instance_metadata_defaults" "this" {
  http_endpoint               = "enabled"
  http_tokens                 = "required"
  http_put_response_hop_limit = 1
  instance_metadata_tags      = "disabled"
}

# --- S3 account-level public access block -----------------------------------

resource "aws_s3_account_public_access_block" "this" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- Config recorder ----------------------------------------------------------

resource "aws_config_configuration_recorder" "this" {
  name     = "${var.name}-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "config" {
  name = "${var.name}-config-recorder"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# --- Data tier consumption ----------------------------------------------------

resource "aws_db_subnet_group" "this" {
  count       = length(var.data_subnet_ids) > 0 ? 1 : 0
  name        = "${var.name}-data"
  description = "Data subnets for ${var.name} - isolated tier, no internet route"
  subnet_ids  = var.data_subnet_ids
  tags        = var.tags
}

# --- Security group pattern for EKS-adjacent workloads ------------------------

resource "aws_security_group" "workload" {
  name        = "${var.name}-workload"
  description = "Baseline workload SG - egress to VPC endpoints / NAT, no inbound by default"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-workload" })

  egress {
    description = "HTTPS egress (via NAT or endpoints)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS to VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["10.20.0.2/32"] # VPC +2 resolver in the example CIDR; adjust per VPC
  }
}

# --- Budget hookup -------------------------------------------------------------
# Delegates to the same thresholds used org-wide: actual 80/100% and
# forecast 100%. Implemented inline here so a single workload account
# can be bootstrapped without the full cost-guardrails stack.

resource "aws_budgets_budget" "workload" {
  count             = length(var.budget_alert_emails) > 0 ? 1 : 0
  name              = "${var.name}-monthly"
  budget_type       = "COST"
  limit_amount      = tostring(var.monthly_budget_limit)
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-01-01_00:00"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_alert_emails
  }
}
