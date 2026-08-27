resource "aws_acm_certificate" "main" {
  count             = var.certificate_arn == "" && var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = merge(
    var.tags_project,
    {
      Name = "${var.project_name}-cert-${var.env_subfix}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  count   = var.certificate_arn == "" && var.domain_name != "" ? 1 : 0
  name    = tolist(aws_acm_certificate.main[0].domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.main[0].domain_validation_options)[0].resource_record_type
  zone_id = var.route53_zone_id
  records = [tolist(aws_acm_certificate.main[0].domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "main" {
  count                   = var.certificate_arn == "" && var.domain_name != "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [aws_route53_record.cert_validation[0].fqdn]
}
