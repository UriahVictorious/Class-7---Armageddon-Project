############################################
# CloudTrail: capture S3 data events for ALB access log writes
############################################

# Bucket to receive CloudTrail logs
resource "aws_s3_bucket" "bns_1c_cloudtrail" {
  bucket = "${var.project_name}-cloudtrail-${data.aws_caller_identity.bns_1c_self01.account_id}"

  tags = {
    Name = "${var.project_name}-cloudtrail-bucket"
  }
}

# Allow CloudTrail service to write to the bucket
resource "aws_s3_bucket_policy" "bns_1c_cloudtrail_policy" {
  bucket = aws_s3_bucket.bns_1c_cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowCloudTrailServiceToWrite"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action = ["s3:GetBucketAcl", "s3:PutObject"]
        Resource = [
          aws_s3_bucket.bns_1c_cloudtrail.arn,
          "${aws_s3_bucket.bns_1c_cloudtrail.arn}/*"
        ]
      }
    ]
  })
}

# CloudTrail trail which captures S3 object-level data events for the ALB logs bucket
resource "aws_cloudtrail" "bns_1c_trail" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = aws_s3_bucket.bns_1c_cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = false

  event_selector {
    read_write_type          = "All"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${var.project_name}-alb-logs-${data.aws_caller_identity.bns_1c_self01.account_id}-new/"]
    }
  }

  depends_on = [aws_s3_bucket_policy.bns_1c_cloudtrail_policy]
}
