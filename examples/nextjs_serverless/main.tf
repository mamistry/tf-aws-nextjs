terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Main region where the resources should be created in
# Should be close to the location of your viewers
provider "aws" {
  region = "us-east-1"
}

# Provider used for creating the Lambda@Edge function which must be deployed
# to us-east-1 region (Should not be changed)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

###########
# Variables
###########

variable "custom_domain" {
  description = "Your custom domain"
  type        = string
  default     = "<custom_domain>" //example.com
}

# Assuming that the ZONE of your domain is already available in your AWS account (Route 53)
# https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/AboutHZWorkingWith.html
variable "custom_domain_zone_name" {
  description = "The Route53 zone name of the custom domain"
  type        = string
  default     = "<custom_domain>" //example.com
}

variable "lambda_array" {
  description = "Lambdas to create"
  type = map(object({
    name = string
    source_dir = string
  }))
  default = {    
    "default" = {
      name = "default",
      source_dir = "<dir_to_source>/default-lambda"
    }
    "image" = {
      name = "image",
      source_dir = "<dir_to_source>/image-lambda"
    }
    "api" = {
      name = "api",
      source_dir = "<dir_to_source>/api-lambda"
    }
    "regeneration" = {
      name = "regeneration",
      source_dir = "<dir_to_source>/regeneration-lambda"
    }
  }
}

variable "cloudfront_cert" {
  type = string
  default = "<cert_arn>"
}

########
# S3 bucket
########
# Note: The bucket name needs to carry the same name as the domain!
# http://stackoverflow.com/a/5048129/2966951
resource "aws_s3_bucket" "beats-nextjs-bucket" {
  bucket = "<bucket_name>"
}

resource "aws_s3_bucket_acl" "b_acl" {
  bucket = aws_s3_bucket.beats-nextjs-bucket.id
  acl    = "private"
}

resource "aws_cloudfront_origin_access_identity" "my-oai" {
  comment = "my-oai"
}

resource "aws_s3_bucket_policy" "cdn-cf-policy" {
  bucket = aws_s3_bucket.beats-nextjs-bucket.id
  policy = data.aws_iam_policy_document.my-cdn-cf-policy.json
}

data "aws_iam_policy_document" "my-cdn-cf-policy" {
  statement {
    sid = "1"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.my-oai.iam_arn]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.beats-nextjs-bucket.arn}/*"
    ]
  }
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket        = "<bucket_name>"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "template_files" {
  source = "hashicorp/dir/template"

  base_dir = "<dir_source>/assets"
  template_vars = {
    # Pass in any values that you wish to use in your templates.
    example = "example-123"
  }
}

module "cloudfront_s3" {
  source                           = "git@github.com:warnermediacode/sports-terraform-aws-nextjs-module.git"
  providers = {
    aws = aws.us_east_1
  }
  environment                      = terraform.workspace 
  s3_bucket_id                     = aws_s3_bucket.beats-nextjs-bucket.id
  s3_bucket_regional_domain_name   = aws_s3_bucket.beats-nextjs-bucket.bucket_regional_domain_name
  s3_bucket_arn                    = aws_s3_bucket.beats-nextjs-bucket.arn
  s3_files                         = module.template_files.files
  custom_domain                    = var.custom_domain
  custom_domain_zone_name          = var.custom_domain_zone_name
  lambda_array                     = var.lambda_array
  certificate_arn                  = var.cloudfront_cert
  lambda_bucket_id                 = aws_s3_bucket.lambda_bucket.id
  cloudfront_access_identity_path  = aws_cloudfront_origin_access_identity.my-oai.cloudfront_access_identity_path
}
