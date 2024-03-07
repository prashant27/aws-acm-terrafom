
variable "root_domain_name" {
  type = string
  default = "domain-nameSS"
}

variable "nlb_name" {
  type = string
  default = "ngnix-nlb"
}

variable "target_group_name" {
  type = string
  default = "nlb-target-ngnix"
}

variable "listner_name" {
  type = string
  default = "nlb-listner"
}

data "aws_route53_zone" "hostedzone" {
  name         = var.root_domain_name
  private_zone = false
}

data "aws_lb" "nlb" {
  name  = "${var.nlb_name}"
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.root_domain_name
  subject_alternative_names = ["*.${var.root_domain_name}"]
  validation_method         = "DNS"
  tags                      = { Name = "test" }

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 resources to perform DNS auto validation
resource "aws_route53_record" "cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.hostedzone.zone_id
}

# resource "aws_acm_certificate_validation" "acm_certificate" {
#   certificate_arn = "${aws_acm_certificate.cert.arn}"
#   validation_record_fqdns = aws_route53_record.cert_validation_record[each.key]
#    // "${aws_route53_record.cert_validation_record.fqdn}",
#   // ]
# }

resource "aws_acm_certificate_validation" "acm_certificate" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_record : record.fqdn]
}

# 
resource "aws_route53_record" "cname_route53_record" {
  zone_id = data.aws_route53_zone.hostedzone.zone_id # Replace with your zone ID
  name    = "lwapp.${var.root_domain_name}" # Replace with your subdomain, Note: not valid with "apex" domains, e.g. example.com
  type    = "CNAME"
  ttl     = "60"
  records = [data.aws_lb.nlb.dns_name]

    #   # comment line 68 and uncomment from 71 to 74 to add alias
    #   alias {
    #     name                   = aws_lb.nlb.dns_name
    #     zone_id                = aws_lb.nlb.zone_id
    #     evaluate_target_health = true
    #   }

}

resource aws_lb_target_group nlb_target_https {
  name = var.target_group_name
  port = 80
  protocol = "TCP"
  target_type = "ip"
  vpc_id = aws_default_vpc.vpc.id
  
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.nlb_target_https.arn
  target_id =        "<IP- if target type is IP>"
  port             = 80
}

resource aws_lb_listener nlb_listner {
  load_balancer_arn = data.aws_lb.nlb.arn
  port = 443
  protocol = "TLS"
  certificate_arn = aws_acm_certificate.cert.arn
  
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.nlb_target_https.arn
  }
}

resource aws_default_vpc vpc {
  # bring default VPC (created w/ account by AWS) into terraform state
  # this is a convenience; we aren't altering (or deleting, with `terraform destroy`) this resource
}