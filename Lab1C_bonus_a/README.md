Student verification (CLI) for Bonus-A
1) Prove EC2 is private (no public IP)
  aws ec2 describe-instances \
  --instance-ids <INSTANCE_ID> \
  --query "Reservations[].Instances[].PublicIpAddress"

Expected: 
  null

2) Prove VPC endpoints exist
  aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=<VPC_ID>" \
  --query "VpcEndpoints[].ServiceName"

Expected: list includes:
  ssm 
  ec2messages 
  ssmmessages 
  logs 
  secretsmanager
  s3

3) Prove Session Manager path works (no SSH)
  aws ssm describe-instance-information \
  --query "InstanceInformationList[].InstanceId"

Expected: your private EC2 instance ID appears

4) Prove the instance can read both config stores
Run from SSM session:
  aws ssm get-parameter --name /lab/db/endpoint
  aws secretsmanager get-secret-value --secret-id <your-secret-name>

5) Prove CloudWatch logs delivery path is available via endpoint
  aws logs describe-log-streams \
    --log-group-name /aws/ec2/<prefix>-rds-app