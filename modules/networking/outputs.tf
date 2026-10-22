output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs (load balancers only - no workloads)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs - primary input for EKS node groups and cluster networking."
  value       = aws_subnet.private[*].id
}

output "data_subnet_ids" {
  description = "Isolated data subnet IDs for RDS / ElastiCache subnet groups."
  value       = aws_subnet.data[*].id
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs."
  value       = aws_nat_gateway.this[*].id
}

output "eks_ready" {
  description = "Convenience map shaped for direct consumption by an EKS module."
  value = {
    vpc_id                = aws_vpc.this.id
    subnet_ids            = aws_subnet.private[*].id
    control_plane_subnets = aws_subnet.private[*].id
  }
}
