# lab2b_honors_origin_driven.tf — Honors A
#
# the app controls caching for /api/public-feed, not the CDN config
# cloudfront uses the AWS managed UseOriginCacheControlHeaders policy
# it only caches if the origin sends Cache-Control: public
# and caches for exactly as long as s-maxage says
#
# flask app must send:
#   Cache-Control: public, s-maxage=30, max-age=0
# on the /api/public-feed route for this to work

locals {
  use_origin_cache_control_headers_policy_id = "83da9c7e-98b4-4e11-a168-04f0df8e2c65"
}
