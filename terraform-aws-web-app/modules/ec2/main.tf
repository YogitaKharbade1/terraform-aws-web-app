data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  ami_id = var.ami_id != null && var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2.id
}

# --- SECURITY GROUPS ---

resource "aws_security_group" "alb" {
  name        = "${var.prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP inbound from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-alb-sg"
  }
}

resource "aws_security_group" "instance" {
  name        = "${var.prefix}-instance-sg"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Allow direct HTTP access from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from anywhere for testing/debugging"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-instance-sg"
  }
}

# --- TARGET GROUPS ---

resource "aws_lb_target_group" "homepage" {
  name        = "TG1-Homepage"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.prefix}-tg-homepage"
  }
}

resource "aws_lb_target_group" "payment" {
  name        = "TG2-Payment"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/payment.html"
    protocol            = "HTTP"
    port                = "80"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.prefix}-tg-payment"
  }
}

resource "aws_lb_target_group" "order" {
  name        = "TG3-Order"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/order.html"
    protocol            = "HTTP"
    port                = "80"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.prefix}-tg-order"
  }
}

# --- APPLICATION LOAD BALANCER ---

resource "aws_lb" "alb" {
  name               = "WebAppALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  tags = {
    Name = "${var.prefix}-alb"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.homepage.arn
  }
}

resource "aws_lb_listener_rule" "payment" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment.arn
  }

  condition {
    path_pattern {
      values = ["/payment*"]
    }
  }
}

resource "aws_lb_listener_rule" "order" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.order.arn
  }

  condition {
    path_pattern {
      values = ["/order*"]
    }
  }
}

# --- LAUNCH TEMPLATE ---

resource "aws_launch_template" "webapp" {
  name_prefix   = "${var.prefix}-template-"
  image_id      = local.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance.id]
  }

  user_data = filebase64("${path.module}/templates/user_data.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.prefix}-asg-instance"
    }
  }
}

# --- AUTO SCALING GROUP ---

resource "aws_autoscaling_group" "asg" {
  name_prefix         = "WebAppASG-"
  desired_capacity    = 3
  min_size            = 3
  max_size            = 6
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [
    aws_lb_target_group.homepage.arn,
    aws_lb_target_group.payment.arn,
    aws_lb_target_group.order.arn
  ]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.webapp.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# --- TARGET TRACKING POLICY ---

resource "aws_autoscaling_policy" "cpu_policy" {
  name                   = "CPU-Target-50"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

# --- STANDALONE DEMO INSTANCE ---

resource "aws_instance" "demo" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.instance.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/templates/user_data.sh")

  tags = {
    Name = "${var.prefix}-demo-instance"
  }
}
