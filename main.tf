############################################
# Locals
############################################
locals {
  name_prefix = var.project_name
}

############################################
# VPC + Internet Gateway
############################################

resource "aws_vpc" "lab1c_vpc1" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc1"
  }
}

resource "aws_internet_gateway" "lab1c_igw" {
  vpc_id = aws_vpc.lab1c_vpc1.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

############################################
# Subnets (Public + Private)
############################################

resource "aws_subnet" "lab1c_public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.lab1c_vpc1.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet0${count.index + 1}"
  }
}

resource "aws_subnet" "lab1c_private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.lab1c_vpc1.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${local.name_prefix}-private-subnet0${count.index + 1}"
  }
}

############################################
# NAT Gateway + EIP
############################################

resource "aws_eip" "lab1c_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "lab1c_nat" {
  allocation_id = aws_eip.lab1c_nat_eip.id
  subnet_id     = aws_subnet.lab1c_public_subnets[0].id

  tags = {
    Name = "${local.name_prefix}-nat"
  }

  depends_on = [aws_internet_gateway.lab1c_igw]
}

############################################
# Routing (Public + Private)
############################################

resource "aws_route_table" "lab1c_public_rt1" {
  vpc_id = aws_vpc.lab1c_vpc1.id

  tags = {
    Name = "${local.name_prefix}-public-rt1"
  }
}

resource "aws_route" "lab1c_public_default_route" {
  route_table_id         = aws_route_table.lab1c_public_rt1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab1c_igw.id
}

resource "aws_route_table_association" "lab1c_public_rta" {
  count          = length(aws_subnet.lab1c_public_subnets)
  subnet_id      = aws_subnet.lab1c_public_subnets[count.index].id
  route_table_id = aws_route_table.lab1c_public_rt1.id
}

resource "aws_route_table" "lab1c_private_rt1" {
  vpc_id = aws_vpc.lab1c_vpc1.id

  tags = {
    Name = "${local.name_prefix}-private-rt1"
  }
}

resource "aws_route" "lab1c_private_default_route" {
  route_table_id         = aws_route_table.lab1c_private_rt1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.lab1c_nat.id
}

resource "aws_route_table_association" "lab1c_private_rta" {
  count          = length(aws_subnet.lab1c_private_subnets)
  subnet_id      = aws_subnet.lab1c_private_subnets[count.index].id
  route_table_id = aws_route_table.lab1c_private_rt1.id
}

############################################
# Security Groups (EC2 + RDS)
############################################

resource "aws_security_group" "lab1c-ec2-sg1" {
  name        = "${local.name_prefix}-ec2-sg1"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.lab1c_vpc1.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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
    Name = "${local.name_prefix}-ec2-sg1"
  }
}

resource "aws_security_group" "lab1c-rds-sg1" {
  name        = "${local.name_prefix}-rds-sg1"
  description = "RDS security group"
  vpc_id      = aws_vpc.lab1c_vpc1.id

  ingress {
    description = "MySQL from EC2 only"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [
      aws_security_group.lab1c-ec2-sg1.id
    ]
  }

  tags = {
    Name = "${local.name_prefix}-rds-sg1"
  }
}

############################################
# RDS Subnet Group
############################################

resource "aws_db_subnet_group" "lab1c_rds_subnet_group1" {
  name       = "${local.name_prefix}-rds-subnet-group1"
  subnet_ids = aws_subnet.lab1c_private_subnets[*].id

  tags = {
    Name = "${local.name_prefix}-rds-subnet-group1"
  }
}

############################################
# RDS Instance (MySQL)
############################################

resource "aws_db_instance" "lab1c_rds1" {
  identifier             = "${local.name_prefix}-rds1"
  engine                 = var.db_engine
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.lab1c_rds_subnet_group1.name
  vpc_security_group_ids = [aws_security_group.lab1c-rds-sg1.id]

  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "${local.name_prefix}-rds1"
  }
}

############################################
# IAM Role + Inline Policy + Instance Profile
############################################

resource "aws_iam_role" "lab1c_ec2_role1" {
  name = "${local.name_prefix}-ec2-role1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lab1c_ec2_inline_policy" {
  name = "${local.name_prefix}-ec2-inline-policy"
  role = aws_iam_role.lab1c_ec2_role1.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadDBSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.lab1c_db_secret21.arn
      },
      {
        Sid    = "EC2Describe"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "lab1c_instance_profile1" {
  name = "${local.name_prefix}-instance-profile1"
  role = aws_iam_role.lab1c_ec2_role1.name
}

############################################
# EC2 Instance (App Host)
############################################

resource "aws_instance" "lab1c_ec2" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.lab1c_public_subnets[0].id
  vpc_security_group_ids = [aws_security_group.lab1c-ec2-sg1.id]
  iam_instance_profile   = aws_iam_instance_profile.lab1c_instance_profile1.name

  key_name = "lab1c"

  tags = {
    Name = "${local.name_prefix}-ec2"
  }
}

############################################
# Parameter Store (SSM Parameters)
############################################

resource "aws_ssm_parameter" "lab1c_db_endpoint_param" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = aws_db_instance.lab1c_rds1.address

  tags = {
    Name = "${local.name_prefix}-param-db-endpoint"
  }
}

resource "aws_ssm_parameter" "lab1c_db_port_param" {
  name  = "/lab/db/port"
  type  = "String"
  value = tostring(aws_db_instance.lab1c_rds1.port)

  tags = {
    Name = "${local.name_prefix}-param-db-port"
  }
}

resource "aws_ssm_parameter" "lab1c_db_name_param" {
  name  = "/lab/db/name"
  type  = "String"
  value = var.db_name

  tags = {
    Name = "${local.name_prefix}-param-db-name"
  }
}

############################################
# Secrets Manager (DB Credentials)
############################################

resource "aws_secretsmanager_secret" "lab1c_db_secret21" {
  name = "${local.name_prefix}/rds-mysql21"
}

resource "aws_secretsmanager_secret_version" "lab1c_db_secret_version21" {
  secret_id = aws_secretsmanager_secret.lab1c_db_secret21.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.lab1c_rds1.address
    port     = aws_db_instance.lab1c_rds1.port
    dbname   = var.db_name
  })
}

############################################
# CloudWatch Logs (Log Group)
############################################

resource "aws_cloudwatch_log_group" "lab1c_log_group1" {
  name              = "/aws/ec2/${local.name_prefix}-rds-app"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-log-group1"
  }
}

############################################
# Custom Metric + Alarm
############################################

resource "aws_cloudwatch_metric_alarm" "lab1c_db_alarm1" {
  alarm_name          = "${local.name_prefix}-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionErrors"
  namespace           = "lab/rdsapp"
  period              = 300
  statistic           = "Sum"
  threshold           = 3

  alarm_actions = [aws_sns_topic.lab1c_sns_topic1.arn]

  tags = {
    Name = "${local.name_prefix}-alarm-db-fail"
  }
}

############################################
# SNS (PagerDuty simulation)
############################################

resource "aws_sns_topic" "lab1c_sns_topic1" {
  name = "${local.name_prefix}-db-incidents"
}

resource "aws_sns_topic_subscription" "lab1c_sns_sub1" {
  topic_arn = aws_sns_topic.lab1c_sns_topic1.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
}

