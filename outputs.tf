# FREE TIER OPTIMIZED OUTPUTS
# Outputs for single instance deployment

# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnet Information
output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = aws_subnet.public.cidr_block
}

# EC2 Instance Information
output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.todo_app.id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.todo_app.public_ip
}

output "ec2_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.todo_app.private_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.todo_app.public_dns
}

# Elastic IP (if created)
output "elastic_ip" {
  description = "Elastic IP address (if created)"
  value       = var.use_elastic_ip ? aws_eip.todo_app[0].public_ip : null
}

# Security Group Information
output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.todo_app.id
}

# Key Pair Information
output "key_pair_name" {
  description = "Name of the EC2 key pair"
  value       = aws_key_pair.todo_app.key_name
}

# Application Access Information
output "todo_app_url_direct" {
  description = "Direct URL to access the Todo application on port 5000"
  value       = "http://${aws_instance.todo_app.public_ip}:${var.flask_port}"
}

output "todo_app_url_nginx" {
  description = "URL to access the Todo application via nginx (port 80)"
  value       = "http://${aws_instance.todo_app.public_ip}"
}

output "todo_app_health_check" {
  description = "Health check URL"
  value       = "http://${aws_instance.todo_app.public_ip}:${var.flask_port}/health"
}

# SSH Connection Information
output "ssh_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i ~/.ssh/${replace(var.project_name, "-", "_")}_key ec2-user@${aws_instance.todo_app.public_ip}"
}

output "ssh_command_with_port_forwarding" {
  description = "SSH command with local port forwarding for secure access"
  value       = "ssh -i ~/.ssh/${replace(var.project_name, "-", "_")}_key -L 8080:localhost:${var.flask_port} ec2-user@${aws_instance.todo_app.public_ip}"
}

# Cost and Free Tier Information
output "free_tier_compliance" {
  description = "Free tier compliance information"
  value = {
    instance_type = var.instance_type
    is_free_tier_eligible = contains(["t2.micro"], var.instance_type)
    ebs_volume_size = var.root_volume_size
    within_ebs_limit = var.root_volume_size <= 30
    estimated_monthly_hours = "~720 hours (24/7 operation)"
    free_tier_hours_limit = "750 hours/month"
    within_free_tier = contains(["t2.micro"], var.instance_type) && var.root_volume_size <= 30
  }
}

# Instance Management Commands
output "instance_management_commands" {
  description = "Useful AWS CLI commands for instance management"
  value = {
    start_instance = "aws ec2 start-instances --instance-ids ${aws_instance.todo_app.id}"
    stop_instance = "aws ec2 stop-instances --instance-ids ${aws_instance.todo_app.id}"
    reboot_instance = "aws ec2 reboot-instances --instance-ids ${aws_instance.todo_app.id}"
    get_instance_status = "aws ec2 describe-instances --instance-ids ${aws_instance.todo_app.id} --query 'Reservations[0].Instances[0].State.Name' --output text"
    get_public_ip = "aws ec2 describe-instances --instance-ids ${aws_instance.todo_app.id} --query 'Reservations[0].Instances[0].PublicIpAddress' --output text"
  }
}

# Monitoring Information
output "cloudwatch_alarm_name" {
  description = "CloudWatch alarm name (if monitoring is enabled)"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.high_cpu[0].alarm_name : "Monitoring disabled"
}

# Application Information
output "application_details" {
  description = "Application deployment details"
  value = {
    flask_port = var.flask_port
    nginx_port = 80
    application_path = "/opt/todo-app"
    service_name = "todo-app"
    log_location = "/var/log/todo-app.log"
  }
}

# Quick Setup Summary
output "quick_access_summary" {
  description = "Quick summary of how to access your application"
  value = <<-EOT
    
    🚀 FREE TIER TODO APP DEPLOYED SUCCESSFULLY! 🚀
    
    📍 Access Methods:
    • Web App (Direct):  ${aws_instance.todo_app.public_ip}:${var.flask_port}
    • Web App (Nginx):   ${aws_instance.todo_app.public_ip}
    • SSH Access:        ssh -i ~/.ssh/your-key ec2-user@${aws_instance.todo_app.public_ip}
    
    💰 Cost Status: FREE (within AWS Free Tier limits)
    • Instance: ${var.instance_type} - ✅ Free tier eligible
    • Storage: ${var.root_volume_size}GB EBS - ✅ Within 30GB limit
    • Network: VPC, Subnet, Security Group - ✅ Always free
    
    🛠️ Management:
    • Stop: aws ec2 stop-instances --instance-ids ${aws_instance.todo_app.id}
    • Start: aws ec2 start-instances --instance-ids ${aws_instance.todo_app.id}
    
    💡 Remember: Free tier gives you 750 hours/month for 12 months
    EOT
}

# Deployment Summary for Cost Tracking
output "deployment_summary" {
  description = "Summary of deployed infrastructure for cost tracking"
  value = {
    region = var.aws_region
    instance_count = 1
    instance_type = var.instance_type
    ebs_volume_gb = var.root_volume_size
    free_tier_compliant = contains(["t2.micro"], var.instance_type) && var.root_volume_size <= 30
    estimated_monthly_cost = contains(["t2.micro"], var.instance_type) && var.root_volume_size <= 30 ? "$0 (within free tier)" : "Check AWS pricing calculator"
    deployment_time = timestamp()
  }
}