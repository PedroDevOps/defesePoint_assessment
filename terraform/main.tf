provider "aws" {
  region = "us-west-2"  
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "${var.environment}-${var.bucket_name}"
  tags = var.tags_list
}

resource "aws_s3_bucket_website_configuration" "website_bucket-bucket-config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website_bucket-access-block" {
  depends_on = [ aws_s3_bucket.website_bucket ]
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow-all" {
  depends_on = [ aws_s3_bucket.website_bucket, aws_s3_bucket_public_access_block.website_bucket-access-block ]
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Principal = "*"
            Action = [
                "s3:GetObject"
            ]
            Resource = [
                "${aws_s3_bucket.website_bucket.arn}/*"
            ]
        }
    ]
  })
}


resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.website_bucket.bucket}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Static website distribution"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website_bucket.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "OAI for my-static-website"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

resource "aws_lambda_function" "image_resize" {
  filename         = "../lambda_function/lambda_function_payload.zip"
  function_name    = "image_resize"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"

  source_code_hash = filebase64sha256("../lambda_function/lambda_function_payload.zip")

  environment {
    variables = {
      BUCKET = aws_s3_bucket.website_bucket.bucket
    }
  }
}

resource "aws_api_gateway_rest_api" "image_api" {
  name        = "ImageResizeAPI"
  description = "API for resizing images"

  endpoint_configuration {
    types = ["EDGE"]
  }
}

resource "aws_api_gateway_resource" "image" {
  rest_api_id = aws_api_gateway_rest_api.image_api.id
  parent_id   = aws_api_gateway_rest_api.image_api.root_resource_id
  path_part   = "image"
}

resource "aws_api_gateway_method" "post_image" {
  rest_api_id   = aws_api_gateway_rest_api.image_api.id
  resource_id   = aws_api_gateway_resource.image.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.image_api.id
  resource_id = aws_api_gateway_resource.image.id
  http_method = aws_api_gateway_method.post_image.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.image_resize.invoke_arn

  depends_on = [aws_lambda_function.image_resize]
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_resize.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.image_api.execution_arn}/*/*"
}

output "website_url" {
  value = aws_cloudfront_distribution.website_distribution.domain_name
}

output "api_url" {
  value = "${aws_api_gateway_rest_api.image_api.execution_arn}/image"
}
