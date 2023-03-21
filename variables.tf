variable "environment" {
  description = "Name of the environement eg. dev or int"
  type = string
}

variable "service_name" {
  description = "Name of the Service"
  type        = string
}

variable "custom_domain" {
  description = "Your custom domain"
  type        = string
}

variable "custom_domain_zone_name" {
  description = "The Route53 zone name of the custom domain"
  type        = string
}

variable "lambda_array" {
  description = "Lambdas to create"
  type = map(object({
    name = string
    source_dir = string
  }))
}

variable "s3_bucket_regional_domain_name" {
  description = "s3 regional domain name"
  type = string
}

variable "s3_bucket_arn" {
  description = "s3 bucket arn"
  type = string
}

variable "certificate_arn" {
  description = "ARN value of the ACM certificate"
  type        = string
}

variable "cloudfront_access_identity_path" {
  description = "ARN value of the ACM certificate"
  type        = string
}
 