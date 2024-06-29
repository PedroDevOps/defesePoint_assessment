resource "aws_s3_bucket" "static_website" {
  bucket = "${var.environment}-${var.bucket_name}"
  tags = var.tags_list
}

resource "aws_s3_bucket_website_configuration" "static_website-bucket-config" {
  bucket = aws_s3_bucket.static_website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "static_website-access-block" {
  depends_on = [ aws_s3_bucket.static_website ]
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow-all" {
  depends_on = [ aws_s3_bucket.static_website, aws_s3_bucket_public_access_block.static_website-access-block ]
  bucket = aws_s3_bucket.static_website.id

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
                "${aws_s3_bucket.static_website.arn}/*"
            ]
        }
    ]
  })
}