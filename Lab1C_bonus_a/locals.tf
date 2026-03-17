############################################
# Bonus A _ Data + Locals
############################################

# Explanation: bns-1c wants to know “who am I in this galaxy?” so ARNs can be scoped properly.
data "aws_caller_identity" "bns-1c_self01" {}

# Explanation: Region matters—hyperspace lanes change per sector.
data "aws_region" "bns-1c_region01" {}

locals {
  # Explanation: Name prefix is the roar that echoes through every tag.
  bns-1c_prefix = var.project_name

  name_prefix = local.bns-1c_prefix


  # TODO: Students should lock this down after apply using the real secret ARN from outputs/state
  bns-1c_secret_arn_guess = "arn:aws:secretsmanager:${data.aws_region.bns-1c_region01.name}:${data.aws_caller_identity.bns-1c_self01.account_id}:secret:${local.bns-1c_prefix}/rds/mysql*"
}