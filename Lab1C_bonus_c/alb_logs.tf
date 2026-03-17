############################################
# ALB access logs S3 bucket (optional)
############################################

resource "aws_s3_bucket" "bns-1c_alb_logs01" {
  count = var.create_alb_logs_resources ? 1 : 0

  bucket = "${var.project_name}-alb-logs-${data.aws_caller_identity.bns_1c_self01.account_id}"
  

  tags = {
    Name = "${var.project_name}-alb-logs-bucket01"
  }
}

resource "aws_s3_bucket_public_access_block" "bns-1c_alb_logs_pab01" {
  count = var.create_alb_logs_resources ? 1 : 0

  bucket                  = aws_s3_bucket.bns-1c_alb_logs01[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_policy" "bns-1c_alb_logs_policy01" {
  count  = var.create_alb_logs_resources ? 1 : 0
  bucket = aws_s3_bucket.bns-1c_alb_logs01[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowELBBucketChecks"
        Effect = "Allow"
        Principal = { Service = "elasticloadbalancing.amazonaws.com" }
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Resource = "${aws_s3_bucket.bns-1c_alb_logs01[0].arn}"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.bns_1c_self01.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:elasticloadbalancing:${data.aws_region.bns_1c_region01.name}:${data.aws_caller_identity.bns_1c_self01.account_id}:loadbalancer/*"
          }
        }
      },
      {
        Sid = "AllowELBToPutLogs"
        Effect = "Allow"
        Principal = { Service = "elasticloadbalancing.amazonaws.com" }
        Action = [
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.bns-1c_alb_logs01[0].arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.bns_1c_self01.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:elasticloadbalancing:${data.aws_region.bns_1c_region01.name}:${data.aws_caller_identity.bns_1c_self01.account_id}:loadbalancer/*"
          }
        }
      }
    ]
  })
}

# Small propagation delay to avoid ALB trying to enable access logs
# before the bucket policy is fully propagated across AWS.
resource "null_resource" "bns-1c_alb_logs_policy_ready" {
  count = var.create_alb_logs_resources ? 1 : 0

  depends_on = [aws_s3_bucket_policy.bns-1c_alb_logs_policy01]

  provisioner "local-exec" {
    command = "sleep 10"
  }
}

# New explicitly-owned bucket + policy (alternative) for ALB access logs
resource "aws_s3_bucket" "bns-1c_alb_logs_new01" {
  count = var.create_alb_logs_resources ? 1 : 0

  bucket = "${var.project_name}-alb-logs-${data.aws_caller_identity.bns_1c_self01.account_id}-new"

  tags = {
    Name = "${var.project_name}-alb-logs-bucket-new01"
  }
}

resource "aws_s3_bucket_policy" "bns-1c_alb_logs_new_policy01" {
  count  = var.create_alb_logs_resources ? 1 : 0
  bucket = aws_s3_bucket.bns-1c_alb_logs_new01[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowELBBucketChecks"
        Effect = "Allow"
        Principal = { Service = "elasticloadbalancing.amazonaws.com" }
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Resource = "${aws_s3_bucket.bns-1c_alb_logs_new01[0].arn}"
      },
      {
        Sid = "AllowELBToPutLogs"
        Effect = "Allow"
        Principal = { Service = "elasticloadbalancing.amazonaws.com" }
        Action = [
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.bns-1c_alb_logs_new01[0].arn}/*"
      }
    ]
  })
}

resource "null_resource" "bns-1c_alb_logs_policy_ready_new" {
  count = var.create_alb_logs_resources ? 1 : 0

  depends_on = [aws_s3_bucket_policy.bns-1c_alb_logs_new_policy01]

  provisioner "local-exec" {
    command = "sleep 10"
  }
}

# Allow ACLs while ensuring bucket owner owns objects
resource "aws_s3_bucket_ownership_controls" "bns-1c_alb_logs_new_ownership01" {
  count  = var.create_alb_logs_resources ? 1 : 0
  bucket = aws_s3_bucket.bns-1c_alb_logs_new01[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
