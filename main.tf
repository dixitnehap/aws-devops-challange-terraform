provider "aws" {
  region = var.aws_region
}


// create S3 bucket
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = var.s3_bucket_name
}

// create source zip file and place in project folder
data "archive_file" "lambda-devops-http-api" {
  type = "zip"

  source_dir  = "${path.module}/devops-http-api"
  output_path = "${path.module}/devops-http-api.zip"
}

// upload zip file that created in previous step in created s3 bucket in step1
resource "aws_s3_bucket_object" "lambda-devops-http-api" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "devops-http-api.zip"
  source = data.archive_file.lambda-devops-http-api.output_path

  etag = filemd5(data.archive_file.lambda-devops-http-api.output_path)
}

// create Lambda function and respective role and polices
resource "aws_lambda_function" "devops-http-api" {
  function_name = "devops-http-api"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_bucket_object.lambda-devops-http-api.key

  runtime = "nodejs12.x"
  handler = "app.lambdaHandler"

  source_code_hash = data.archive_file.lambda-devops-http-api.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "devops-http-api" {
  name = "/aws/lambda/${aws_lambda_function.devops-http-api.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


// create API Gateway
resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}


resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

/*
resource "aws_apigatewayv2_integration" "devops-http-api-get" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.devops-http-api.invoke_arn
  integration_type   = "AWS"
  integration_method = "GET"
}
*/

resource "aws_apigatewayv2_integration" "devops-http-api-post" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.devops-http-api.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}


resource "aws_apigatewayv2_route" "devops-http-api-get" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /api"
  target    = "integrations/${aws_apigatewayv2_integration.devops-http-api-post.id}"
}


resource "aws_apigatewayv2_route" "devops-http-api-post" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /api"
  target    = "integrations/${aws_apigatewayv2_integration.devops-http-api-post.id}"
}


resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.devops-http-api.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}
