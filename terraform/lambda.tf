resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "date_function" {
  filename         = "../lambda_function/lambda_function_payload.zip"
  function_name    = "date_function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
}

resource "aws_api_gateway_rest_api" "date_api" {
  name        = "Date API"
  description = "API for getting current date"
}

resource "aws_api_gateway_resource" "date_resource" {
  rest_api_id = aws_api_gateway_rest_api.date_api.id
  parent_id   = aws_api_gateway_rest_api.date_api.root_resource_id
  path_part   = "date"
}

resource "aws_api_gateway_method" "date_method" {
  rest_api_id   = aws_api_gateway_rest_api.date_api.id
  resource_id   = aws_api_gateway_resource.date_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.date_api.id
  resource_id             = aws_api_gateway_resource.date_resource.id
  http_method             = aws_api_gateway_method.date_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.date_function.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.date_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.date_api.execution_arn}/*/*"
}

output "api_gateway_url" {
  value = "${aws_api_gateway_rest_api.date_api.execution_arn}/date"
}
