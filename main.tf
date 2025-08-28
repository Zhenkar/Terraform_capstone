# FREE TIER OPTIMIZED TERRAFORM CONFIGURATION
# This configuration stays within AWS Free Tier limits (single instance, no load balancer)

# Configure the AWS Provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CostCenter  = "FreeTier"
    }
  }
}

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source to get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create VPC - FREE
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc-free"
  }
}

# Create Internet Gateway - FREE
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw-free"
  }
}

# Create single public subnet (only one needed for single instance) - FREE
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-free"
    Type = "Public"
  }
}

# Create route table for public subnet - FREE
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-free"
  }
}

# Associate route table with public subnet - FREE
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create security group for EC2 instance - FREE
resource "aws_security_group" "todo_app" {
  name        = "${var.project_name}-sg-free"
  description = "Security group for Todo App EC2 instance (Free Tier)"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # HTTP access for Flask app
  ingress {
    description = "Flask App"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access for nginx reverse proxy
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-free"
  }
}

# Create key pair for EC2 instance - FREE
resource "aws_key_pair" "todo_app" {
  key_name   = "${var.project_name}-key-free"
  public_key = var.public_key

  tags = {
    Name = "${var.project_name}-key-pair-free"
  }
}

# User data script to install and setup the Flask todo app
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_port = var.flask_port
  }))
}

# Create SINGLE EC2 instance - FREE TIER (t2.micro, 750 hours/month)
resource "aws_instance" "todo_app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type  # t2.micro for free tier
  key_name              = aws_key_pair.todo_app.key_name
  vpc_security_group_ids = [aws_security_group.todo_app.id]
  subnet_id             = aws_subnet.public.id
  user_data             = local.user_data

  # FREE TIER: 30GB EBS storage, using 8GB to stay well within limits
  root_block_device {
    volume_type = "gp2"  # gp2 is cheaper than gp3 for small volumes
    volume_size = var.root_volume_size  # 8GB for free tier
    encrypted   = true
  }

  # Disable detailed monitoring to avoid potential charges
  monitoring = false

  # Enable termination protection for production
  disable_api_termination = var.enable_termination_protection

  tags = {
    Name = "${var.project_name}-ec2-free"
    Role = "TodoApp"
    FreeTier = "true"
  }
}

# Optional: Create CloudWatch alarm for instance monitoring - FREE (within limits)
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-high-cpu-free"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"

  dimensions = {
    InstanceId = aws_instance.todo_app.id
  }

  tags = {
    Name = "${var.project_name}-cpu-alarm-free"
  }
}

# Create an Elastic IP (optional) - FREE while attached to running instance
resource "aws_eip" "todo_app" {
  count = var.use_elastic_ip ? 1 : 0

  instance = aws_instance.todo_app.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-eip-free"
  }

  # Ensure EIP is created after internet gateway
  depends_on = [aws_internet_gateway.main]
}

# Optional: Create IAM role for EC2 instance (for future enhancements) - FREE
resource "aws_iam_role" "ec2_role" {
  count = var.create_iam_role ? 1 : 0

  name = "${var.project_name}-ec2-role-free"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role-free"
  }
}

# Create instance profile - FREE
resource "aws_iam_instance_profile" "ec2_profile" {
  count = var.create_iam_role ? 1 : 0

  name = "${var.project_name}-ec2-profile-free"
  role = aws_iam_role.ec2_role[0].name

  tags = {
    Name = "${var.project_name}-ec2-profile-free"
  }
}