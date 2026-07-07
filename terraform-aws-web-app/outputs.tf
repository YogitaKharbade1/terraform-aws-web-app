output "demo_instance_public_ip" {
  description = "The public IP address of the standalone demo EC2 instance to access directly"
  value       = module.ec2.demo_public_ip
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.ec2.alb_dns_name
}
