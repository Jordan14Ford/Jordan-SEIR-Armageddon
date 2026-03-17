# lab2b_response_headers_policy.tf — Be A Man Challenge (Lab 2B Deliverable A.4)
#
# Response headers policy for /static/*: adds explicit Cache-Control so CloudFront
# sends a consistent Cache-Control header on static responses. The lab requires
# "Response headers policy for explicit Cache-Control on static responses (or security headers)."
# This policy is attached to the /static/* ordered_cache_behavior in lab2_cloudfront_alb.tf.

resource "aws_cloudfront_response_headers_policy" "cloudyjones_static_rhp" {
  name    = "${var.project}-static-response-headers-policy"
  comment = "Be A Man: explicit Cache-Control for /static/* responses"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      value    = "public, max-age=86400"
      override = true
    }
  }
}
