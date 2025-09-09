resource "random_id" "oac_suffix" {
  byte_length = 4
  
}

resource "aws_cloudfront_distribution" "realtime_chat_distribution" {
  origin {
    domain_name = var.realtime_chat__bucket_regional_domain_name
     origin_id   = "s3-realtime-chat-origin"
     origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  enabled             = true
  comment             = "CloudFront distribution for Realtime Chat"
  default_root_object = "index.html"

    aliases = [
    var.chat_domain_name,   # Replace with your actual domain name, e.g., "www.baylenwebsite.xyz"
   
  ]

  default_cache_behavior {
    target_origin_id       = "s3-realtime-chat-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.chat_acm_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name        = "RealtimeChatDistribution"
    Environment = "Dev"
  }
  
}