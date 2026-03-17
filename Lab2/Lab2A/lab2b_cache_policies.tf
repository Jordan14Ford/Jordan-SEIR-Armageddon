# lab2b_cache_policies.tf
# cache policies and origin request policies for lab 2B
#
# a cache policy controls two things:
#   1. what gets included in the cache key (what makes two requests "the same")
#   2. what TTLs apply to cached objects
#
# an origin request policy controls what gets forwarded to the origin
# on a cache miss — headers, cookies, query strings
#
# these are separate because cache key and forwarding are different concerns:
# you might forward something to the origin without including it in the cache key

# static assets cache policy — aggressive caching
# min=60s, default=1 day, max=30 days
# cache key is path only — no query strings, no cookies, no headers
# this means ?v=1 and ?v=2 serve the same cached object
resource "aws_cloudfront_cache_policy" "cloudyjones_static_cp" {
  name        = "${var.project}-static-cache-policy"
  comment     = "Aggressive caching for /static/* — path-only cache key"
  min_ttl     = 60
  default_ttl = 86400
  max_ttl     = 2592000

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

# API cache policy — caching completely disabled
# TTL 0/0/0 means every request goes to the origin, nothing is stored
resource "aws_cloudfront_cache_policy" "cloudyjones_api_cp" {
  name        = "${var.project}-api-cache-policy"
  comment     = "Caching disabled for /api/* — every request hits origin"
  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# Static origin request policy — minimal forwarding (Lab 2B Deliverable A)
# For /static/* we only need the request to reach the origin; no cookies/headers/QS in cache key
resource "aws_cloudfront_origin_request_policy" "cloudyjones_static_orp" {
  name    = "${var.project}-static-origin-request-policy"
  comment = "Minimal forwarding for /static/* — path only"

  cookies_config {
    cookie_behavior = "none"
  }

  headers_config {
    header_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "none"
  }
}

# API origin request policy — forward everything the app needs
# authorization, content-type, cookies, query strings all forwarded
# we do NOT include these in the cache key — forwarding != cache key
resource "aws_cloudfront_origin_request_policy" "cloudyjones_api_orp" {
  name    = "${var.project}-api-origin-request-policy"
  comment = "Forward auth headers, cookies, QS to API origin"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Content-Type", "Accept", "Origin"]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}
