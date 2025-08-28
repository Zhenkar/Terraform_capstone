# FREE TIER OPTIMIZED VARIABLES
# All defaults are set to stay within AWS Free Tier limits

# AWS Region
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"  # Free tier available in all regions
}

# Project configuration
variable "project_name" {
  description = "Name of the project - will be used as prefix for resources"
  type        = string
  default     = "flask-todo-free"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# VPC Configuration - FREE
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Single subnet for FREE tier (only one instance needed)
variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# EC2 Configuration - FREE TIER OPTIMIZED
variable "instance_type" {
  description = "EC2 instance type - t2.micro is free tier eligible"
  type        = string
  default     = "t2.micro"  # FREE: 750 hours/month for first 12 months
  
  validation {
    condition = contains([
      "t2.nano", "t2.micro", "t2.small", "t2.medium",
      "t3.nano", "t3.micro", "t3.small"
    ], var.instance_type)
    error_message = "For cost optimization, use t2.micro (free tier) or other small instances."
  }
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB - optimized for free tier"
  type        = number
  default     = 8  # FREE: 30GB total limit, using 8GB to stay well within limits
  
  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 30
    error_message = "Root volume size must be between 8 and 30 GB for free tier compliance."
  }
}

# Security Configuration
variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH to EC2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # WARNING: Restrict to your IP for production!
  
  validation {
    condition = alltrue([
      for cidr in var.allowed_ssh_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All allowed_ssh_cidrs must be valid CIDR blocks."
  }
}

variable "public_key" {
  description = "Public key content for EC2 key pair (generate with: ssh-keygen -t rsa -b 4096)"
  type        = string
  
  validation {
    condition     = can(regex("^ssh-(rsa|ed25519)", var.public_key))
    error_message = "Public key must be a valid SSH public key starting with ssh-rsa or ssh-ed25519."
  }
}

# Application Configuration
variable "flask_port" {
  description = "Port on which Flask application will run"
  type        = number
  default     = 5000
  
  validation {
    condition     = var.flask_port >= 1024 && var.flask_port <= 65535
    error_message = "Flask port must be between 1024 and 65535."
  }
}

# Cost Optimization Features
variable "use_elastic_ip" {
  description = "Whether to create an Elastic IP (FREE while attached, $0.005/hour if detached)"
  type        = bool
  default     = false  # Set to false to avoid potential charges
}

variable "enable_monitoring" {
  description = "Whether to enable CloudWatch alarms (FREE within limits: 10 alarms)"
  type        = bool
  default     = true
}

variable "enable_termination_protection" {
  description = "Whether to enable EC2 termination protection"
  type        = bool
  default     = false  # Set to true for production
}

variable "create_iam_role" {
  description = "Whether to create IAM role for EC2 instance (for future enhancements)"
  type        = bool
  default     = false  # Set to true if you need AWS service access
}

# Auto-shutdown configuration (cost saving)
variable "auto_shutdown_time" {
  description = "Time to automatically shutdown instance (24h format, empty to disable)"
  type        = string
  default     = ""  # Example: "22:00" for 10 PM shutdown
  
  validation {
    condition = var.auto_shutdown_time == "" || can(regex("^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$", var.auto_shutdown_time))
    error_message = "Auto shutdown time must be in HH:MM format (24-hour) or empty string."
  }
}

variable "auto_startup_time" {
  description = "Time to automatically start instance (24h format, empty to disable)"
  type        = string
  default     = ""  # Example: "08:00" for 8 AM startup
  
  validation {
    condition = var.auto_startup_time == "" || can(regex("^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$", var.auto_startup_time))
    error_message = "Auto startup time must be in HH:MM format (24-hour) or empty string."
  }
}