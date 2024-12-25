provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source              = "../modules/vpc" # Reference to the reusable module
  vpc_name            = var.vpc_name
  cidr_block          = var.cidr_block
  enable_dns_support  = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
}

module "subnets" {
  source          = "../modules/subnets"
  vpc_id          = module.vpc.vpc_id
  subnet_config   = var.subnet_config
  tags            = { User = "vky" }
}

module "igw" {
  source    = "../modules/igw"
  vpc_id    = module.vpc.vpc_id
  igw_name  = var.igw_name
  tags      = { User = "Vky" }
}

