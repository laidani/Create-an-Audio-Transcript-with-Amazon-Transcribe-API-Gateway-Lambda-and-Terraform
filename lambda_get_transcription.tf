# Lambda
resource "aws_lambda_permission" "get_transcription_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_transcription_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*"
}

resource "aws_lambda_function" "get_transcription_lambda" {
  filename         = local.transcription_lambda_file_name
  function_name    = local.transcription_function_name
  role             = aws_iam_role.upload_audio_role.arn
  handler          = "lambda_get_transcription.lambda_handler"
  runtime          = "python3.8"
  timeout          = 25
  source_code_hash = filebase64sha256(local.transcription_lambda_file_name)
}

resource "aws_iam_role" "transcription_role" {
  name = "${local.transcription_function_name}_role"

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

resource "aws_iam_policy" "transcription_lambda_policy" {
  name        = "${local.transcription_function_name}-policy"
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
        "Action" : ["transcribe:*"],
        "Resource" : "*",
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "transcription_role_policy_attachment" {
  role       = aws_iam_role.transcription_role.name
  policy_arn = aws_iam_policy.transcription_lambda_policy.arn
}

locals {
  transcription_function_name    = "Get_Transcription_Lambda"
  transcription_lambda_file_name = "lambda_get_transcription.zip"
}