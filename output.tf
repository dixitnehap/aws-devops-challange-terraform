output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.devops-http-api.function_name
}