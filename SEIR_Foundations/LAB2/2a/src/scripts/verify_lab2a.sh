#!/usr/bin/env bash
set -euo pipefail

# ===== USER INPUTS =====
# Fill these in before running. Or export env vars: DIST_ID, HOSTNAME, ALB_DNS, HOSTED_ZONE_ID
# Run this script from the repo root (parent of Lab2/).
AWS_REGION="${AWS_REGION:-us-east-1}"
DIST_ID="${DIST_ID:-REPLACE_ME}"
HOSTNAME="${HOSTNAME:-REPLACE_ME}"           # example: app.cloudyjones.xyz
ALB_DNS="${ALB_DNS:-REPLACE_ME}"             # example: cloudyjones-alb01-xxx.us-east-1.elb.amazonaws.com
HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-REPLACE_ME}"
# =======================

OUTDIR="Lab2/Lab2A/deliverables/verification"
mkdir -p "$OUTDIR"

echo "Running Lab2A verification..."
echo "Region: $AWS_REGION"
echo "Distribution ID: $DIST_ID"
echo "Hostname: $HOSTNAME"
echo "ALB DNS: $ALB_DNS"

echo "=== CloudFront distribution ===" | tee "$OUTDIR/cloudfront_distribution.txt"
aws cloudfront get-distribution \
  --id "$DIST_ID" \
  --output json | tee -a "$OUTDIR/cloudfront_distribution.txt"

echo "=== CloudFront behaviors ===" | tee "$OUTDIR/cloudfront_behaviors.txt"
aws cloudfront get-distribution-config \
  --id "$DIST_ID" \
  --output json | tee -a "$OUTDIR/cloudfront_behaviors.txt"

echo "=== WAF attachment for distribution ===" | tee "$OUTDIR/waf_for_distribution.txt"
aws wafv2 get-web-acl-for-resource \
  --resource-arn "arn:aws:cloudfront::$(aws sts get-caller-identity --query Account --output text):distribution/$DIST_ID" \
  --scope CLOUDFRONT \
  --region us-east-1 \
  --output json 2>&1 | tee -a "$OUTDIR/waf_for_distribution.txt" || true

echo "=== Route53 records ===" | tee "$OUTDIR/route53_records.txt"
aws route53 list-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --output json | tee -a "$OUTDIR/route53_records.txt"

echo "=== Public hostname headers ===" | tee "$OUTDIR/app_via_domain_headers.txt"
curl -sI "https://$HOSTNAME" 2>&1 | tee -a "$OUTDIR/app_via_domain_headers.txt" || true

echo "=== Public hostname verbose response ===" | tee "$OUTDIR/app_via_domain_verbose.txt"
curl -sv "https://$HOSTNAME" -o /dev/null 2>&1 | tee -a "$OUTDIR/app_via_domain_verbose.txt" || true

echo "=== Direct ALB headers (HTTPS; -k to skip cert validation for ALB hostname) ===" | tee "$OUTDIR/alb_direct_headers.txt"
curl -sIk "https://$ALB_DNS" 2>&1 | tee -a "$OUTDIR/alb_direct_headers.txt" || true

echo "=== Direct ALB verbose response ===" | tee "$OUTDIR/alb_direct_verbose.txt"
curl -svk "https://$ALB_DNS" -o /dev/null 2>&1 | tee -a "$OUTDIR/alb_direct_verbose.txt" || true

echo "Verification complete. Outputs saved to $OUTDIR"
