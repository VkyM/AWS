output "subnet_ids" {
  description = "The IDs of the created subnets"
  value       = [for subnet in aws_subnet.subnet : subnet.id]
}

output "subnet_arns" {
  description = "The ARNs of the created subnets"
  value       = [for subnet in aws_subnet.subnet : subnet.arn]
}
