resource "aws_apigatewayv2_api" "http_api" {
  name          = "transcribe_api"
  protocol_type = "HTTP"
  description   = "HTTP API to send audio files to Lambda"

  cors_configuration {
    allow_credentials = false
    allow_headers     = []
    allow_methods     = ["GET", "POST"]
    allow_origins     = ["*"]
    expose_headers    = []
    max_age           = 0
  }
}

# Upload audio endpoint
resource "aws_apigatewayv2_integration" "api_upload" {
  api_id = aws_apigatewayv2_api.http_api.id

  integration_uri  = aws_lambda_function.upload_audit_lambda.invoke_arn
  integration_type = "AWS_PROXY"
}

resource "aws_apigatewayv2_route" "api_upload" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.api_upload.id}"
}

# Get transcription endpoint
resource "aws_apigatewayv2_integration" "api_transcription" {
  api_id = aws_apigatewayv2_api.http_api.id

  integration_uri  = aws_lambda_function.get_transcription_lambda.invoke_arn
  integration_type = "AWS_PROXY"
}

resource "aws_apigatewayv2_route" "api_transcription" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /transcription"
  target    = "integrations/${aws_apigatewayv2_integration.api_transcription.id}"
}

# Stage
resource "aws_apigatewayv2_stage" "api_stage_dev" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "dev"
  auto_deploy = true

  depends_on = [aws_apigatewayv2_integration.api_upload]
}