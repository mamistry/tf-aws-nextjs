data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
  }
}

data aws_iam_policy_document lambda_s3_sqs {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]

    resources = [
       "${var.s3_bucket_arn}/*"
    ]
  }
  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]

    resources = [
      aws_sqs_queue.sqs_default_queue.arn
    ]
  }
}

resource "aws_iam_role" "default_lambda_exec" {
  name = "${var.environment}-LambdaRscExecRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_policy.json
}

resource aws_iam_policy lambda_s3_sqs {
  name        = "${var.environment}-lambda-s3-sqs-permissions"
  description = "Contains S3 and SQS permissions for lambda"
  policy      = data.aws_iam_policy_document.lambda_s3_sqs.json
}

resource "aws_iam_role_policy_attachment" "default_lambda_policy" {
  role       = aws_iam_role.default_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "attach-s3-sqs" {
  role       = aws_iam_role.default_lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_sqs.arn
}