#!/usr/bin/env bash
# Run this once from your machine to capture the last verification proofs.
# Usage: ./Lab2/Lab2A/scripts/capture_curl_proofs.sh   (from repo root)
#    or: ./capture_curl_proofs.sh                      (from Lab2/Lab2A/scripts)
# Requires: curl, and that you can reach the domain and ALB.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Script is at Lab2/Lab2A/scripts/ so repo root is 3 levels up
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
VERIFY="$REPO_ROOT/Lab2/Lab2A/deliverables/verification"
DOMAIN="app.cloudyjones.xyz"
ALB_DNS="cloudyjones-alb01-837551053.us-east-1.elb.amazonaws.com"

mkdir -p "$VERIFY"

echo "Capturing app via domain..."
curl -sI "https://$DOMAIN" 2>&1 | tee "$VERIFY/app_via_domain_headers.txt"

echo "Capturing app verbose..."
curl -sv "https://$DOMAIN" -o /dev/null 2>&1 | tee "$VERIFY/app_via_domain_verbose.txt"

echo "Capturing direct ALB (expect 403)..."
curl -sI "http://$ALB_DNS" 2>&1 | tee "$VERIFY/alb_direct_headers.txt"

echo "Capturing direct ALB verbose..."
curl -sv "http://$ALB_DNS" -o /dev/null 2>&1 | tee "$VERIFY/alb_direct_verbose.txt"

echo "Done. Check $VERIFY/alb_direct_headers.txt for 403."
