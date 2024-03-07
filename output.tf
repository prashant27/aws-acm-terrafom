output "route53_zone" {
    value = "${data.aws_route53_zone.hostedzone.zone_id}"
}

output "acm_certificate" {
    value = aws_acm_certificate.cert.arn
  
}

output "domain_validation" {
    value = aws_acm_certificate.cert.domain_validation_options
  
}

output "cert_validation_record" {
  value = aws_route53_record.cert_validation_record
}

output "aws_acm_certificate_validation" {
  value = aws_acm_certificate_validation.acm_certificate
}

output "aws_lb" {
  value = "${data.aws_lb.nlb.dns_name}"
}

# output "aws_lb_target_group" {
#   value = aws_lb_target_group.nlb_target_https
# }

# output "aws_lb_listener" {
#   value = aws_lb_listener.nlb_listner
# }