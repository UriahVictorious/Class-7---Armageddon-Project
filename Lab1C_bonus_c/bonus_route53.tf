############################################
# Bonus B - Route53 (Hosted Zone + DNS records + ACM validation + ALIAS to ALB)
############################################

locals {
  # Explanation: bns-1c needs a home planet—Route53 hosted zone is your DNS territory.
  bns_1c_zone_name = var.domain_name

  # Explanation: Use either Terraform-managed zone or a pre-existing zone ID (students choose their destiny).
  bns_1c_zone_id = var.manage_route53_in_terraform ? aws_route53_zone.bns_1c_zone01[0].zone_id : var.route53_hosted_zone_id

  # Explanation: This is the app address that will growl at the galaxy (app.bns-1c-growl.com).
  bns_1c_app_fqdn = "${var.app_subdomain}.${var.domain_name}"
}

############################################
# Hosted Zone (optional creation)
############################################

# Explanation: A hosted zone is like claiming Kashyyyk in DNS—names here become law across the galaxy.
resource "aws_route53_zone" "bns_1c_zone01" {
  count = var.manage_route53_in_terraform ? 1 : 0

  name = local.bns_1c_zone_name

  tags = {
    Name = "${var.project_name}-zone01"
  }
}

############################################
# ACM DNS Validation Records
############################################

# Explanation: ACM asks “prove you own this planet”—DNS validation is bns-1c roaring in the right place.
resource "aws_route53_record" "bns-1c_acm_validation_records01" {
  for_each = (var.certificate_validation_method == "DNS" && (var.manage_route53_in_terraform || var.route53_hosted_zone_id != "")) ? {
    for dvo in aws_acm_certificate.bns-1c_acm_cert01.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = var.manage_route53_in_terraform ? aws_route53_zone.bns_1c_zone01[0].zone_id : var.route53_hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60

  records = [each.value.record]
}

# Explanation: This ties the “proof record” back to ACM—bns-1c gets his green checkmark for TLS.
/* Certificate validation is handled in bonus_b.tf to reference Route53 records created above. */

############################################
# DNS records: Apex + App alias to ALB
############################################

resource "aws_route53_record" "bns-1c_apex_alias01" {
  count = (var.manage_route53_in_terraform || var.route53_hosted_zone_id != "") ? 1 : 0

  zone_id = var.manage_route53_in_terraform ? aws_route53_zone.bns_1c_zone01[0].zone_id : var.route53_hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.bns-1c_alb01.dns_name
    zone_id                = aws_lb.bns-1c_alb01.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "bns-1c_app_alias01" {
  count = (var.manage_route53_in_terraform || var.route53_hosted_zone_id != "") ? 1 : 0

  zone_id = var.manage_route53_in_terraform ? aws_route53_zone.bns_1c_zone01[0].zone_id : var.route53_hosted_zone_id
  name    = var.app_subdomain
  type    = "A"

  alias {
    name                   = aws_lb.bns-1c_alb01.dns_name
    zone_id                = aws_lb.bns-1c_alb01.zone_id
    evaluate_target_health = false
  }
}