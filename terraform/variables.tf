variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  default     = "new"
}

variable "private_key_path" {
  description = "Path to the private key file for Ansible SSH access"
  type        = string
  default     = "/var/lib/jenkins/.ssh/new.pem"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

