output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.devops-http-api.function_name
}

output "api_url" {
  description = "Name of the Lambda function."

  value = "${aws_apigatewayv2_api.lambda.api_endpoint}/${aws_apigatewayv2_stage.lambda.name}"
}