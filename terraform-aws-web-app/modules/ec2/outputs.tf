output "demo_public_ip" {
  description = "The public IP address of the standalone demo EC2 instance"
  value       = aws_instance.demo.public_ip
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}
