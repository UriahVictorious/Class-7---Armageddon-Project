# Explanation: Outputs are your mission report—what got built and where to find it.
output "bns-1c_vpc_id" {
  value = aws_vpc.bns-1c_vpc1.id
}

output "bns-1c_public_subnet_ids" {
  value = aws_subnet.bns-1c_public_subnets[*].id
}

output "bns-1c_private_subnet_ids" {
  value = aws_subnet.bns-1c_private_subnets[*].id
}

/*output "bns-1c_ec2_instance_id" {
  value = aws_instance.bns-1c_ec2.id
}*/

output "bns-1c_rds_endpoint" {
  value = aws_db_instance.bns-1c_rds1.address
}

output "bns-1c_sns_topic_arn" {
  value = aws_sns_topic.bns-1c_sns_topic1.arn
}

output "bns-1c_log_group_name" {
  value = aws_cloudwatch_log_group.bns-1c_log_group1.name
}

#Bonus_A outputs (append to outputs.tf)

# Explanation: These outputs prove bns-1c built private hyperspace lanes (endpoints) instead of public chaos.
output "bns-1c_vpce_ssm_id" {
  value = aws_vpc_endpoint.bns-1c_vpce_ssm1.id
}

output "bns-1c_vpce_logs_id" {
  value = aws_vpc_endpoint.bns-1c_vpce_logs1.id
}

output "bns-1c_vpce_secrets_id" {
  value = aws_vpc_endpoint.bns-1c_vpce_secrets1.id
}

output "bns-1c_vpce_s3_id" {
  value = aws_vpc_endpoint.bns-1c_vpce_s3_gw1.id
}

output "bns-1c_private_ec2_instance_id_bonus" {
  value = aws_instance.bns-1c_ec2_private_bonus.id
}

output "bns-1c_logs_bucket_name" {
  value = var.create_alb_logs_resources ? aws_s3_bucket.bns-1c_alb_logs_new01[0].id : "null"
}

output "bns-1c_route53_zone_id" {
  value = local.bns_1c_zone_id
}

output "bns-1c_app_url_https" {
  value = "https://${var.app_subdomain}.${var.domain_name}"  
}

#Bonus_B outputs (append to outputs.tf)

