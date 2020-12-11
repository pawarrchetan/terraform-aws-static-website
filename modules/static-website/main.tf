provider "aws" {
  region = "us-east-1"
  alias  = "useast"
}

provider "aws" {
  region = "eu-central-1"
}

data "aws_caller_identity" "current" {}

#ACM
module "acm" {
  source = "../acm-certificate"

  region                    = "us-east-1"
  domain_name               = var.domain_name
  zone_id                   = var.zone_id
  validate_certificate      = var.validate_certificate
  subject_alternative_names = var.alternate_domain_names
}

#S3
#Creates bucket to store logs
locals {
  logs_bucket_name = format("%s%s", replace(replace("${data.aws_caller_identity.current.account_id}-${var.domain_name}", "*", "wildcard"), ".", "-"), "-logs")
}

#Creates bucket to store the website logs
resource "aws_s3_bucket" "static_website_logs" {
  bucket = local.logs_bucket_name
  acl    = "log-delivery-write"

  # Comment the following line if you are uncomfortable with Terraform destroying the bucket even if this one is not empty 
  force_destroy = true

  tags = {
    heritage = "terraform"
    changed  = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

#Creates bucket to store the static website contents
resource "aws_s3_bucket" "static_website" {
  bucket = replace(replace("${data.aws_caller_identity.current.account_id}-${var.domain_name}", "*", "wildcard"), ".", "-")

  logging {
    target_bucket = aws_s3_bucket.static_website_logs.bucket
    target_prefix = "static-website-logs/"
  }

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  lifecycle {
    ignore_changes = [tags]
  }

  tags = {
    Name     = replace(replace("${var.domain_name}-static-website", "*", "wildcard"), ".", "-")
    heritage = "terraform"
    changed  = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  }
}

data "aws_iam_policy_document" "static_website" {
  statement {
    sid       = "1"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_website.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "static_website" {
  bucket = aws_s3_bucket.static_website.id
  policy = data.aws_iam_policy_document.static_website.json
}

locals {
  s3_origin_id = "frontEndS3Origin"
}

#CDN
#Create a cloudfront distribution
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "CDN origin access identity"
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.static_website.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  comment             = "CDN for ${var.domain_name} S3 Bucket"
  enabled             = true
  is_ipv6_enabled     = true
  aliases             = [var.domain_name]
  default_root_object = "index.html"

  logging_config {
    bucket = aws_s3_bucket.static_website_logs.bucket_domain_name
    prefix = "cdn-logs/"
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = module.acm.this_acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  tags = {
    Name = "Static-Website-Distribution"
  }
}

#Create a Route53 record alias for CDN
resource "aws_route53_record" "alias" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}