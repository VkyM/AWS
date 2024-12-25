variable "vpc_id" {
  description = "The ID of the VPC where the subnets will be created"
  type        = string
}

variable "subnet_config" {
  description = "Configuration for subnets"
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = bool
    name                    = string
  }))
}

variable "tags" {
  description = "Additional tags to apply to the subnets"
  type        = map(string)
  default     = {}
}
