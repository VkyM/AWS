provider "aws" {
  region = "ap-south-1"
}

# -------------------------------
# Replace these values
# -------------------------------

variable "key_name" {
  default = "ubuntu"  # 🔑 Replace with your EC2 key pair name
}

variable "subnet_id" {
  default = "subnet-0b412973ce5c227d4"  # 🌐 Replace with your subnet ID
}

variable "security_group_id" {
  default = "sg-00c9988b38278efbb"  # 🔒 Replace with your security group ID
}

variable "ami_id" {
  default = "ami-0f918f7e67a3323f0"  # 🖼️ Ubuntu server 24 AMI for us-east-1
}

# -------------------------------
# EC2 Instance Resource
# -------------------------------

resource "aws_instance" "multi_ec2" {
  count                       = 2
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true  # Get public IP

  tags = {
    Name = "MyEC2-${count.index + 1}"
  }
}
