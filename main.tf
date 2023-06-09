########
# Locals
########

locals {
  # A wildcard domain(ex: *.example.com) has to be added when using atomic deployments:
  aliases = [var.custom_domain, "*.${var.custom_domain}"]
  domain = "${var.environment}.${var.custom_domain}"
}

########
# lambdas
########

resource "aws_s3_bucket" "lambda_bucket" {
  bucket        = "${var.environment}-lambda-bucket-${var.service_name}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "lambdas" {
  for_each = var.lambda_array

  source = "./terraform_modules/lambda"

  name = each.value["name"]
  output_path = "${each.value["name"]}-lambda.zip"
  source_dir  = each.value["source_dir"]
  function_name = "${var.environment}_${each.value["name"]}_path"
  s3_bucket_arn = var.s3_bucket_arn
  s3_bucket_id = aws_s3_bucket.lambda_bucket.id
  s3_object_key = "${each.value["name"]}_path.zip"
  role_arn = aws_iam_role.default_lambda_exec.arn
  sqs_default_queue_arn = aws_sqs_queue.sqs_default_queue.arn
}

#######################
# Cloudfront setup
#######################

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    origin_id   = local.domain
    domain_name = var.s3_bucket_regional_domain_name
    s3_origin_config {
      origin_access_identity = var.cloudfront_access_identity_path
    }
  }

  # If using route53 aliases for DNS we need to declare it here too, otherwise we'll get 403s.
  aliases = [local.domain]

  enabled             = true


  ordered_cache_behavior {
    path_pattern           = "_next/static/*"
    target_origin_id       = local.domain
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "https-only"
    compress = true
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

  }

  ordered_cache_behavior {
    path_pattern           = "static/*"
    target_origin_id       = local.domain
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "https-only"
    compress = true
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

  }

  dynamic "ordered_cache_behavior" {
     for_each = {
      for key, value in var.lambda_array : "arn" => module.lambdas[value.name].lambda_function_arn
      if value.name == "default" && module.lambdas[value.name].lambda_function_arn != null
    }

    content {
      path_pattern           = "_next/data/*"
      target_origin_id       = local.domain
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "https-only"
      compress = true
      forwarded_values {
        query_string = true
        cookies {
          forward = "all"
        }
      }

      lambda_function_association{
        event_type   = "origin-request"   
        include_body = true
        lambda_arn   = ordered_cache_behavior.value
      }
      lambda_function_association{
        event_type   = "origin-response"   
        include_body = false
        lambda_arn   = ordered_cache_behavior.value
      }
    }

  }

  dynamic "ordered_cache_behavior" {
     for_each = {
      for key, value in var.lambda_array : "arn" => module.lambdas[value.name].lambda_function_arn
      if value.name == "image" && module.lambdas[value.name].lambda_function_arn != null
    }

    content {
      path_pattern           = "_next/image*"
      target_origin_id       = local.domain
      allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "https-only"
      compress = true
      min_ttl                = 0
      default_ttl            = 3600
      max_ttl                = 86400
      forwarded_values {
        query_string = true
        headers      = ["Accept"]
        cookies {
          forward = "all"
        }
      }

      lambda_function_association{
        event_type   = "origin-request"   
        include_body = true
        lambda_arn   = ordered_cache_behavior.value
      }
    }
  }

  dynamic "ordered_cache_behavior" {
     for_each = {
      for key, value in var.lambda_array : "arn" => module.lambdas[value.name].lambda_function_arn
      if value.name == "api" && module.lambdas[value.name].lambda_function_arn != null
    }

    content {
      path_pattern           = "api/*"
      target_origin_id       = local.domain
      allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "https-only"
      compress = true
      min_ttl                = 0
      default_ttl            = 3600
      max_ttl                = 86400
      forwarded_values {
        query_string = true
        headers      = ["Host", "Authorization"]
        cookies {
          forward = "all"
        }
      }

      lambda_function_association{
        event_type   = "origin-request"   
        include_body = true
        lambda_arn   = ordered_cache_behavior.value
      }
    }
  }

  dynamic "default_cache_behavior" {
    for_each = {
      for key, value in var.lambda_array : "arn" => module.lambdas[value.name].lambda_function_arn
      if value.name == "default" && module.lambdas[value.name].lambda_function_arn != null
    }

    content {
      allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = local.domain
      compress = true

      forwarded_values {
        query_string = true
        cookies {
          forward = "none"
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 3600
      max_ttl                = 86400

      lambda_function_association{
        event_type   = "origin-request"   
        include_body = true
        lambda_arn   = default_cache_behavior.value
      }
      lambda_function_association{
        event_type   = "origin-response"   
        include_body = false
        lambda_arn   = default_cache_behavior.value
      }
    }
  }

  # The cheapest priceclass
  price_class = "PriceClass_100"

  # This is required to be specified even if it's not used.
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.certificate_arn
    ssl_support_method = "sni-only"
  }
}

resource "aws_sqs_queue" "sqs_default_queue" {
  name                  = "${var.environment}-regeneration-nextjs.fifo"
  fifo_queue            = true
  deduplication_scope   = "messageGroup"
  fifo_throughput_limit = "perMessageGroupId"
}

# output "test_data" {
#   value = {
#       for key, value in var.lambda_array : value.name => {
#         "arn": module.lambdas[value.name].lambda_function_arn,
#         "lp": value.source_dir
#       }
#       if value.name == "regeneration" && module.lambdas[value.name].lambda_function_arn != null
#     }
# }
