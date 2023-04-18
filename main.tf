# Configure the AWS provider
provider "aws" {
  region = "ap-southeast-2"
}

# Create a VPC and subnets
resource "aws_vpc" "nginx_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "nginx_subnet_public" {
  vpc_id = aws_vpc.nginx_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "nginx_subnet_private" {
  vpc_id = aws_vpc.nginx_vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = false
}

# Create an ECS cluster
resource "aws_ecs_cluster" "nginx_cluster" {
  name = "nginx-cluster"
  capacity_providers = ["FARGATE"]
}

# Create a security group for the ECS tasks
resource "aws_security_group" "nginx_security_group" {
  name_prefix = "nginx-sg"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
}

# Create a task definition for the nginx container
resource "aws_ecs_task_definition" "nginx_task_definition" {
  family = "nginx-task"
  container_definitions = jsonencode([{
    name = "nginx-container"
    image = "nginx:latest"
    port_mappings = [{
      container_port = 80
      host_port = 0
    }]
  }])
  memory = 512
  cpu = 256
}

# Create an ECS service to run the nginx container
resource "aws_ecs_service" "nginx_service" {
  name = "nginx-service"
  cluster = aws_ecs_cluster.nginx_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task_definition.arn
  desired_count = 2
  launch_type = "FARGATE"
  network_configuration {
    security_groups = [aws_security_group.nginx_security_group.id]
    subnets = [aws_subnet.nginx_subnet_public.id, aws_subnet.nginx_subnet_private.id]
    assign_public_ip = true
  }
}

# Create an Application Load Balancer
resource "aws_lb" "nginx_lb" {
  name = "nginx-lb"
  subnets = [aws_subnet.nginx_subnet_public.id]
  security_groups = [aws_security_group.nginx_lb_security_group.id]
  internal = false

  tags = {
    Name = "nginx-lb"
  }
}

# Create a target group for the nginx service
resource "aws_lb_target_group" "nginx_target_group" {
  name = "nginx-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.nginx_vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    timeout = 10
    interval = 30
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

# Register the ECS service with the target group
resource "aws_lb_target_group_attachment" "nginx_target_group_attachment" {
  target_group_arn = aws_lb_target_group.nginx_target_group.arn
  target_id = aws_ecs_service.nginx_service.id
  port = 80
}

# Enable flow logs for the VPC
resource "aws_flow_log" "nginx_flow_log" {
  log_destination = "arn:aws:logs:ap-southeast-2:123456789012:log-group:/aws/vpc/flow-logs"
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.nginx_vpc.id
}

# Enable AWS Config for the account
resource "aws_config_delivery_channel" "default" {
  s3_bucket_name = "my-config-bucket"
}

# Enable AWS CloudTrail for the account
resource "aws_cloudtrail" "nginx_cloudtrail" {
  name = "nginx-cloudtrail"
  s3_bucket_name = "my-cloudtrail-bucket"
  include_global_service_events = true
}
