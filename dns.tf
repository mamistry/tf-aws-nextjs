#######################
# Route53 Domain record
#######################

# Get the hosted zone for the custom domain
data "aws_route53_zone" "custom_domain_zone" {
  name = var.custom_domain_zone_name
}

# Create a new record in Route 53 for the domain
resource "aws_route53_record" "cloudfront_alias_domain" {

  zone_id = data.aws_route53_zone.custom_domain_zone.zone_id
  name    = local.domain
  type    = "A"

  alias {
    name = aws_cloudfront_distribution.cdn.domain_name
    zone_id = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}