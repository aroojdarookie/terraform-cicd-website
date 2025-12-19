provider "aws" {
  region = "ap-southeast-2"
}

# Generate unique bucket name
resource "random_id" "bucket_id" {
  byte_length = 4
}

# 1️⃣ Create S3 bucket
resource "aws_s3_bucket" "website_bucket" {
  bucket = "my-cicd-website-${random_id.bucket_id.hex}"
}

# 2️⃣ Disable Block Public Access FIRST
resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 3️⃣ Enable static website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }
}

# 4️⃣ Attach public read policy (AFTER block is disabled)
resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  depends_on = [
    aws_s3_bucket_public_access_block.public
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })
}

# 5️⃣ Upload index.html
resource "aws_s3_object" "html" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  source       = "../website/index.html"
  content_type = "text/html"

  depends_on = [
    aws_s3_bucket_policy.public_policy
  ]
}

