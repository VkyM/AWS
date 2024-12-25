output "subnet_ids" {
  description = "The IDs of the subnets for Project A"
  value       = module.subnets.subnet_ids
}

output "subnet_arns" {
  description = "The ARNs of the subnets for Project A"
  value       = module.subnets.subnet_arns
}

output "igw_id" {
  description = "The ID of the Internet Gateway for Project A"
  value       = module.igw.igw_id
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway for Project A"
  value       = module.igw.igw_arn
}

