variable "vpc_name" {
  description = "The name of the VPC"
  default     = "project-a-vpc"
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "enable_dns_support" {
  description = "Enable DNS support for the VPC"
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames for the VPC"
  default     = false
}

variable "subnet_config" {
  description = "Subnet configurations for the project"
  default = {
    subnet1 = {
      cidr_block              = "10.0.1.0/24"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true
      name                    = "project-a-public-subnet-1"
    },
    subnet2 = {
      cidr_block              = "10.0.2.0/24"
      availability_zone       = "us-east-1b"
      map_public_ip_on_launch = false
      name                    = "project-a-private-subnet-1"
    }
  }
}

variable "subnet_ids" {
  description = "Subnets to associate with the route table"
  default     = []
}

variable "igw_name" {
  description = "The name of the Internet Gateway"
  default     = "project-a-igw"
}


