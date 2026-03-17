############################################
# VPC + Internet Gateway
############################################

resource "aws_vpc" "bns-1c_vpc1" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}_vpc1"
  }
}

resource "aws_internet_gateway" "bns-1c_igw" {
  vpc_id = aws_vpc.bns-1c_vpc1.id

  tags = {
    Name = "${var.project_name}_igw"
  }
}

############################################
# Subnets (Public + Private)
############################################

resource "aws_subnet" "bns-1c_public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.bns-1c_vpc1.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}_public_subnet0${count.index + 1}"
  }
}

resource "aws_subnet" "bns-1c_private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.bns-1c_vpc1.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}_private_subnet0${count.index + 1}"
  }
}

############################################
# NAT Gateway + EIP
############################################

resource "aws_eip" "bns-1c_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}_nat_eip"
  }
}

resource "aws_nat_gateway" "bns-1c_nat" {
  allocation_id = aws_eip.bns-1c_nat_eip.id
  subnet_id     = aws_subnet.bns-1c_public_subnets[0].id

  tags = {
    Name = "${var.project_name}_nat"
  }

  depends_on = [aws_internet_gateway.bns-1c_igw]
}

############################################
# Routing (Public + Private)
############################################

resource "aws_route_table" "bns-1c_public_rt1" {
  vpc_id = aws_vpc.bns-1c_vpc1.id

  tags = {
    Name = "${var.project_name}_public_rt1"
  }
}

resource "aws_route" "bns-1c_public_default_route" {
  route_table_id         = aws_route_table.bns-1c_public_rt1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.bns-1c_igw.id
}

resource "aws_route_table_association" "bns-1c_public_rta" {
  count          = length(aws_subnet.bns-1c_public_subnets)
  subnet_id      = aws_subnet.bns-1c_public_subnets[count.index].id
  route_table_id = aws_route_table.bns-1c_public_rt1.id
}

resource "aws_route_table" "bns-1c_private_rt1" {
  vpc_id = aws_vpc.bns-1c_vpc1.id

  tags = {
    Name = "${var.project_name}_private_rt1"
  }
}

resource "aws_route" "bns-1c_private_default_route" {
  route_table_id         = aws_route_table.bns-1c_private_rt1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.bns-1c_nat.id
}

resource "aws_route_table_association" "bns-1c_private_rta" {
  count          = length(aws_subnet.bns-1c_private_subnets)
  subnet_id      = aws_subnet.bns-1c_private_subnets[count.index].id
  route_table_id = aws_route_table.bns-1c_private_rt1.id
}

############################################
# Security Groups (EC2 + RDS)
############################################

resource "aws_security_group" "bns-1c_ec2_sg1" {
  name        = "${var.project_name}_ec2_sg1"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.bns-1c_vpc1.id

  /*ingress {
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
  }*/

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}_ec2_sg1"
  }
}

resource "aws_security_group" "bns-1c_rds_sg1" {
  name        = "${var.project_name}_rds_sg1"
  description = "RDS security group"
  vpc_id      = aws_vpc.bns-1c_vpc1.id

  ingress {
    description = "MySQL from EC2 only"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [
      aws_security_group.bns-1c_ec2_sg1.id
    ]
  }

  tags = {
    Name = "${var.project_name}_rds_sg1"
  }
}

############################################
# Security Group for VPC Interface Endpoints
############################################

# Explanation: Even endpoints need guards—bns-1c_bonus_a posts a Wookiee at every airlock.
resource "aws_security_group" "bns-1c_vpce_sg1" {
  name        = "${local.bns-1c_prefix}_vpce_sg1"
  description = "SG for VPC Interface Endpoints"
  vpc_id      = aws_vpc.bns-1c_vpc1.id

  # TODO: Students must allow inbound 443 FROM the EC2 SG (or VPC CIDR) to endpoints.
  # NOTE: Interface endpoints ENIs receive traffic on 443.

  ingress {
    description     = "Allow inbound 443 from the EC2 Security Group"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.bns-1c_ec2_sg1.id]
  }

  tags = {
    Name = "${local.bns-1c_prefix}_vpce_sg1"
  }
}

############################################
# RDS Subnet Group
############################################

resource "aws_db_subnet_group" "bns-1c_rds_subnet_group1" {
  name       = "${var.project_name}_rds_subnet_group1"
  subnet_ids = aws_subnet.bns-1c_private_subnets[*].id

  tags = {
    Name = "${var.project_name}_rds_subnet_group1"
  }
}

############################################
# Move EC2 into PRIVATE subnet (no public IP)
############################################

# Explanation: bns-1c_bonus_a hates exposure—private subnets keep your compute off the public holonet.
resource "aws_instance" "bns-1c_ec2_private_bonus" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.bns-1c_private_subnets[0].id
  vpc_security_group_ids = [aws_security_group.bns-1c_ec2_sg1.id]
  iam_instance_profile   = aws_iam_instance_profile.bns-1c_instance_profile.name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y amazon-ssm-agent
              systemctl start amazon-ssm-agent
              systemctl enable amazon-ssm-agent
              EOF
  )

  tags = {
    Name = "${local.bns-1c_prefix}_ec2_private"
  }
}

############################################
# VPC Endpoint _ S3 (Gateway)
############################################

# Explanation: S3 is the supply depot—without this, your private world starves (updates, artifacts, logs).
resource "aws_vpc_endpoint" "bns-1c_vpce_s3_gw1" {
  vpc_id            = aws_vpc.bns-1c_vpc1.id
  service_name      = "com.amazonaws.${data.aws_region.bns-1c_region01.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.bns-1c_private_rt1.id
  ]

  tags = {
    Name = "${local.bns-1c_prefix}_vpce_s3_gw1"
  }
}

############################################
# VPC Endpoints _ SSM (Interface)
############################################

# Explanation: SSM is your Force choke—remote control without SSH, and nobody sees your keys.
resource "aws_vpc_endpoint" "bns-1c_vpce_ssm1" {
  vpc_id              = aws_vpc.bns-1c_vpc1.id
  service_name        = "com.amazonaws.${data.aws_region.bns-1c_region01.name}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.bns-1c_private_subnets[*].id
  security_group_ids = [aws_security_group.bns-1c_vpce_sg1.id]

  tags = {
    Name = "${local.bns-1c_prefix}_vpce_ssm1"
  }
}

# Explanation: ec2messages is the Wookiee messenger—SSM sessions won’t work without it.
resource "aws_vpc_endpoint" "bns-1c_vpce_ec2messages1" {
  vpc_id              = aws_vpc.bns-1c_vpc1.id
  service_name        = "com.amazonaws.${data.aws_region.bns-1c_region01.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.bns-1c_private_subnets[*].id
  security_group_ids = [aws_security_group.bns-1c_vpce_sg1.id]

  tags = {
    Name = "${local.bns-1c_prefix}_vpce_ec2messages1"
  }
}

# Explanation: ssmmessages is the holonet channel—Session Manager needs it to talk back.
resource "aws_vpc_endpoint" "bns-1c_vpce_ssmmessages01" {
  vpc_id              = aws_vpc.bns-1c_vpc1.id
  service_name        = "com.amazonaws.${data.aws_region.bns-1c_region01.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.bns-1c_private_subnets[*].id
  security_group_ids = [aws_security_group.bns-1c_vpce_sg1.id]

  tags = {
    Name = "${local.bns-1c_prefix}_vpce_ssmmessages1"
  }
}

############################################
# VPC Endpoint _ CloudWatch Logs (Interface)
############################################

# Explanation: CloudWatch Logs is the ship’s black box—bns-1c_bonus_a wants crash data, always.
resource "aws_vpc_endpoint" "bns-1c_vpce_logs1" {
  vpc_id              = aws_vpc.bns-1c_vpc1.id
  service_name        = "com.amazonaws.${data.aws_region.bns-1c_region01.name}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.bns-1c_private_subnets[*].id
  security_group_ids = [aws_security_group.bns-1c_vpce_sg1.id]

  tags = {
    Name = "${local.bns-1c_prefix}_vpce_logs1"
  }
}

############################################
# VPC Endpoint _ Secrets Manager (Interface)
############################################

# Explanation: Secrets Manager is the locked vault—bns-1c_bonus_a doesn’t put passwords on sticky notes.
resource "aws_vpc_endpoint" "bns-1c_vpce_secrets1" {
  vpc_id              = aws_vpc.bns-1c_vpc1.id
  service_name        = "com.amazonaws.${data.aws_region.bns-1c_region01.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.bns-1c_private_subnets[*].id
  security_group_ids = [aws_security_group.bns-1c_vpce_sg1.id]

  tags = {
    Name = "${local.bns-1c_prefix}_vpce_secrets1"
  }
}

############################################
# Parameter Store (SSM Parameters)
############################################

resource "aws_ssm_parameter" "bns-1c_db_endpoint_param" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = aws_db_instance.bns-1c_rds1.address

  tags = {
    Name = "${var.project_name}_param_db_endpoint"
  }
}

resource "aws_ssm_parameter" "bns-1c_db_port_param" {
  name  = "/lab/db/port"
  type  = "String"
  value = tostring(aws_db_instance.bns-1c_rds1.port)

  tags = {
    Name = "${var.project_name}_param_db_port"
  }
}

resource "aws_ssm_parameter" "bns-1c_db_name_param" {
  name  = "/lab/db/name"
  type  = "String"
  value = var.db_name

  tags = {
    Name = "${var.project_name}_param_db_name"
  }
}

############################################
# Secrets Manager (DB Credentials)
############################################

resource "aws_secretsmanager_secret" "bns-1c_db_secret05" {
  name = "${var.project_name}/rds_mysql_v5"
}

resource "aws_secretsmanager_secret_version" "bns-1c_db_secret05" {
  secret_id = aws_secretsmanager_secret.bns-1c_db_secret05.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.bns-1c_rds1.address
    port     = aws_db_instance.bns-1c_rds1.port
    dbname   = var.db_name
  })
}

############################################
# CloudWatch Logs (Log Group)
############################################

resource "aws_cloudwatch_log_group" "bns-1c_log_group1" {
  name              = "ec2/${var.project_name}_rds_app"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}_log_group1"
  }
}

############################################
# Custom Metric + Alarm
############################################

resource "aws_cloudwatch_metric_alarm" "bns-1c_db_alarm1" {
  alarm_name          = "${var.project_name}_db_connection_failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionErrors"
  namespace           = "lab/rdsapp"
  period              = 300
  statistic           = "Sum"
  threshold           = 3

  alarm_actions = [aws_sns_topic.bns-1c_sns_topic1.arn]

  tags = {
    Name = "${var.project_name}_alarm_db_fail"
  }
}

############################################
# SNS (PagerDuty simulation)
############################################

resource "aws_sns_topic" "bns-1c_sns_topic1" {
  name = "${var.project_name}_db_incidents"
}

resource "aws_sns_topic_subscription" "bns-1c_sns_sub1" {
  topic_arn = aws_sns_topic.bns-1c_sns_topic1.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
}