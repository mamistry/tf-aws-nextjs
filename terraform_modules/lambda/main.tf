locals {
  empty_hash = "hznHbmgfkAkjuQDJ3w73XPQh05yrtUZQxLmtGbanbYU="
}

data "archive_file" "default_lambda" {
  output_path = var.output_path
  source_dir  = var.source_dir
  type        = "zip"
}

resource "aws_lambda_function" "default_path" {
  count = data.archive_file.default_lambda.output_base64sha256 != local.empty_hash ? 1 : 0

  function_name = var.function_name
  description   = "Managed by WBD"
  publish = true

  s3_bucket = var.s3_bucket_id
  s3_key    = aws_s3_object.lambda_default.key

  runtime = "nodejs14.x"
  handler = "index.handler"

  dynamic "environment" {
    for_each = var.env_vars != null ? [0] : []
    content {
      variables = var.env_vars
    }
  }

  source_code_hash = data.archive_file.default_lambda.output_base64sha256

  role = var.role_arn
  timeout = 10
  memory_size = 512
  
}


resource "aws_cloudwatch_log_group" "default_lambda" {
  count = data.archive_file.default_lambda.output_base64sha256 != local.empty_hash ? 1 : 0
  name = "/aws/lambda/${aws_lambda_function.default_path.0.function_name}"

  retention_in_days = 14
}

resource "aws_s3_object" "lambda_default" {
  bucket = var.s3_bucket_id

  key    = var.s3_object_key
  source = data.archive_file.default_lambda.output_path

  etag = filemd5(data.archive_file.default_lambda.output_path)
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  count            = var.name == "regeneration" ? 1 : 0

  event_source_arn = var.sqs_default_queue_arn
  enabled          = true
  function_name    = aws_lambda_function.default_path[0].arn
  batch_size       = 1
}