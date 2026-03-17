Student Deliverables:

Screenshot of: RDS SG inbound rule using source = sg-ec2-lab EC2 role attached /list output showing at least 3 notes

Short answers: A) Why is DB inbound source restricted to the EC2 security group? B) What port does MySQL use? C) Why is Secrets Manager better than storing creds in code/user-data?

Evidence for Audits / Labs (Recommended Output)

aws ec2 describe-security-groups --group-ids sg-0123456789abcdef0 > sg.json aws rds describe-db-instances --db-instance-identifier mydb01 > rds.json aws secretsmanager describe-secret --secret-id my-db-secret > secret.json aws ec2 describe-instances --instance-ids i-0123456789abcdef0 > instance.json aws iam list-attached-role-policies --role-name MyEC2Role > role-policies.json


# Class-7---Armageddon-Project
