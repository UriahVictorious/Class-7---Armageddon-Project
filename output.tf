# Explanation: Outputs are your mission report—what got built and where to find it.

output "lab1c_vpc_id" {
  value = aws_vpc.lab1c_vpc1.id
}

output "lab1c_public_subnet_ids" {
  value = aws_subnet.lab1c_public_subnets[*].id
}

output "lab1c_private_subnet_ids" {
  value = aws_subnet.lab1c_private_subnets[*].id
}

output "lab1c_ec2_instance_id" {
  value = aws_instance.lab1c_ec2.id
}

output "lab1c_ec2_public_ip" {
  value = aws_instance.lab1c_ec2.public_ip
}

output "lab1c_ec2_public_dns" {
  value = aws_instance.lab1c_ec2.public_dns
}

output "lab1c_rds_endpoint" {
  value = aws_db_instance.lab1c_rds1.address
}

output "lab1c_rds_port" {
  value = aws_db_instance.lab1c_rds1.port
}

output "lab1c_sns_topic_arn" {
  value = aws_sns_topic.lab1c_sns_topic1.arn
}

output "lab1c_log_group_name" {
  value = aws_cloudwatch_log_group.lab1c_log_group1.name
}

output "lab1c_db_secret_arn" {
  value = aws_secretsmanager_secret.lab1c_db_secret21.arn
}

output "lab1c_ssm_db_endpoint_param" {
  value = aws_ssm_parameter.lab1c_db_endpoint_param.name
}

output "lab1c_ssm_db_port_param" {
  value = aws_ssm_parameter.lab1c_db_port_param.name
}

output "lab1c_ssm_db_name_param" {
  value = aws_ssm_parameter.lab1c_db_name_param.name
}
