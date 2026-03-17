variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for naming resources"
  type        = string
  default     = "lab-1c"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.245.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.245.1.0/24", "10.245.2.0/24", "10.245.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.245.11.0/24", "10.245.12.0/24", "10.245.13.0/24"]
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "ec2_ami_id" {
  description = "AMI ID for EC2"
  type        = string
  default     = "ami-0532be01f26a3de55"
}

variable "aws_key_pair_name" {
  description = "To allow SSH access into ec2"
  type = string
  default = "lab1c"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "db_engine" {
  description = "RDS engine"
  type        = string
  default     = "mysql"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "labdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "sns_email_endpoint" {
  description = "Email for SNS alerts"
  type        = string
  default     = "uriahvictorious@gmail.com"
}
