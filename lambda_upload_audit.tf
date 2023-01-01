# Lambda
resource "aws_lambda_permission" "upload_audit_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_audit_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*"
}

resource "aws_lambda_function" "upload_audit_lambda" {
  filename         = local.upload_audio_lambda_file_name
  function_name    = local.upload_audio_function_name
  role             = aws_iam_role.upload_audio_role.arn
  handler          = "lambda_upload_audio.lambda_handler"
  runtime          = "python3.8"
  timeout          = 25
  source_code_hash = filebase64sha256(local.upload_audio_lambda_file_name)

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.transcript_bucket.bucket
    }
  }
}

resource "aws_iam_role" "upload_audio_role" {
  name = "${local.upload_audio_function_name}_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "upload_audit_lambda_policy" {
  name        = "${local.upload_audio_function_name}-policy"
  description = "Policy for ${local.upload_audio_function_name}"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Effect" : "Allow",
        "Action" : ["s3:*"],
        "Resource" : "${aws_s3_bucket.transcript_bucket.arn}/*"
      },
      {
        "Action" : ["transcribe:*"],
        "Resource" : "*",
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "upload_audio_role_policy_attachment" {
  role       = aws_iam_role.upload_audio_role.name
  policy_arn = aws_iam_policy.upload_audit_lambda_policy.arn
}

locals {
  upload_audio_function_name    = "Upload_Audio_Lambda"
  upload_audio_lambda_file_name = "lambda_upload_audio.zip"
}