output "certificate_arn" {
  description = "Certificate for the domain"
  value       = module.acm.this_acm_certificate_arn
}

output "cdn_domain_name" {
  description = "Domain name of the Cloudfront Distribution"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "s3_bucket" {
  description = "S3 Bucket"
  value       = aws_s3_bucket.static_website.bucket
}
