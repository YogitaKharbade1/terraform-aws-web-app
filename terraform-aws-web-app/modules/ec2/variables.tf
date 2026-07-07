variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to deploy the instances and load balancer"
  type        = list(string)
}

variable "prefix" {
  description = "Prefix for resources created by this module"
  type        = string
  default     = "webapp"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "Optional custom AMI ID. If null, the latest Amazon Linux 2 AMI will be used."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Optional name of the key pair to use for EC2 instances"
  type        = string
  default     = null
}
