# Target AWS Region for deployment
aws_region = "ap-south-1"

# Prefix used to name all resources
prefix = "webapp"

# Instance type for both ASG instances and the demo instance
instance_type = "t3.micro"

# Optional: Provide a custom key pair name to SSH into instances
# key_name = "mum"

# Optional: Provide a specific AMI ID manually. If left commented out, 
# Terraform will automatically fetch the latest Amazon Linux 2 AMI.
# ami_id = "ami-06da78c5c433dceda"
