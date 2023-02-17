output "lambda_function_arn" {
  value = data.archive_file.default_lambda.output_base64sha256 != local.empty_hash ? aws_lambda_function.default_path.0.qualified_arn : null
}

output "lambda_name" {
  value = var.name
}
