############################################
# RDS Instance (MySQL)
############################################

resource "aws_db_instance" "bns-1c_rds1" {
  identifier        = "${local.name_prefix}-rds1"
  engine            = var.db_engine
  instance_class    = var.db_instance_class
  allocated_storage = 20
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.bns-1c_rds_subnet_group1.name
  vpc_security_group_ids = [aws_security_group.bns-1c_rds_sg1.id]

  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "${local.name_prefix}_rds1"
  }
}

############################################
# IAM Role + Inline Policy + Instance Profile
############################################

resource "aws_iam_role" "bns-1c_ec2_role" {
  name = "bns-1c_ec2_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "bns-1c_ec2_inline_policy" {
  name = "${local.name_prefix}_ec2_inline_policy"
  role = aws_iam_role.bns-1c_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadDBSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.bns-1c_db_secret09.arn
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

resource "aws_iam_instance_profile" "bns-1c_instance_profile" {
  name = "${local.name_prefix}_instance_profile"
  role = aws_iam_role.bns-1c_ec2_role.name
}

############################################
# Least_Privilege IAM (BONUS A)
############################################

# Explanation: lab1c_bonus_a doesn’t hand out the Falcon keys—this policy scopes reads to your lab paths only.
resource "aws_iam_policy" "bns-1c_leastpriv_read_params" {
  name        = "${local.bns_1c_prefix}_lp_ssm_read"
  description = "Least_privilege read for SSM Parameter Store under /lab/db/*"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadLabDbParams"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.bns_1c_region01.name}:${data.aws_caller_identity.bns_1c_self01.account_id}:parameter/lab/db/*"
        ]
      }
    ]
  })
}

# Explanation: lab1c_bonus_a only opens *this* vault—GetSecretValue for only your secret (not the whole planet).
resource "aws_iam_policy" "bns-1c_leastpriv_read_secret" {
  name        = "${local.bns_1c_prefix}_lp_secrets_read"
  description = "Least_privilege read for the lab DB secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadOnlyLabSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = local.bns_1c_secret_arn_guess
      }
    ]
  })
}

# Explanation: When the Falcon logs scream, this lets lab1c_bonus_a ship logs to CloudWatch without giving away the Death Star plans.
resource "aws_iam_policy" "bns-1c_leastpriv_cwlogs" {
  name        = "${local.bns_1c_prefix}_lp_cwlogs"
  description = "Least_privilege CloudWatch Logs write for the app log group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.bns-1c_log_group1.arn}:*"
        ]
      }
    ]
  })
}

# Explanation: Attach the scoped policies—lab1c_bonus_a loves power, but only the safe kind.
resource "aws_iam_role_policy_attachment" "bns-1c_attach_lp_params" {
  role       = aws_iam_role.bns-1c_ec2_role.name
  policy_arn = aws_iam_policy.bns-1c_leastpriv_read_params.arn
}

resource "aws_iam_role_policy_attachment" "bns-1c_attach_lp_secret" {
  role       = aws_iam_role.bns-1c_ec2_role.name
  policy_arn = aws_iam_policy.bns-1c_leastpriv_read_secret.arn
}

resource "aws_iam_role_policy_attachment" "bns-1c_attach_lp_cwlogs" {
  role       = aws_iam_role.bns-1c_ec2_role.name
  policy_arn = aws_iam_policy.bns-1c_leastpriv_cwlogs.arn
}

resource "aws_iam_role_policy_attachment" "bns-1c_attach_ssm_managed" {
  role       = aws_iam_role.bns-1c_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}