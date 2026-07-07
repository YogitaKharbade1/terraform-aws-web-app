# Target AWS Region for deployment
aws_region = "us-east-1"

# Prefix used to name all resources
prefix = "webapp"

# Instance type for both ASG instances and the demo instance
instance_type = "t2.micro"

# Optional: Provide a custom key pair name to SSH into instances
# key_name = "my-ssh-key"

# Optional: Provide a specific AMI ID manually. If left commented out, 
# Terraform will automatically fetch the latest Amazon Linux 2 AMI.
# ami_id = "ami-0c7217cdde317cfec"
