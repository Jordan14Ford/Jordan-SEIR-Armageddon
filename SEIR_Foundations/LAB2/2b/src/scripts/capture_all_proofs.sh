#!/usr/bin/env bash
# =============================================================================
# capture_all_proofs.sh
#
# Run this from the repo root (Desktop/TWC/Armageddon) after terraform apply.
# It captures every curl proof required by 2B Deliverables D.1, D.2, D.3,
# ManA (public-feed Miss->Hit->Miss), and 2A origin cloaking.
#
# What it saves and why:
#   2A/  - prove CloudFront is in front and ALB is blocked
#   2B/  - prove static caches, API never caches, query strings stripped
#   ManA - prove origin-driven caching works (public-feed Hit) and
#          api/list is never cached (private, no-store)
#
# How to use:
#   cd /Users/jordanford/Desktop/TWC/Armageddon
#   chmod +x Lab2/capture_all_proofs.sh
#   ./Lab2/capture_all_proofs.sh
#
# Expected run time: ~90 seconds (because of the 35s sleep for ManA Miss->Hit->Miss)
# =============================================================================

set -euo pipefail

# ---- Your real values (pre-filled) ----
CF_URL="https://app.cloudyjones.xyz"
ALB_DNS="cloudyjones-alb01-837551053.us-east-1.elb.amazonaws.com"

# ---- Proof folder roots ----
PROOF_2A="Lab2/Lab2A/deliverables/verification"
PROOF_2B="Lab2/Lab2B/deliverables/proof"

# ---- Colour helpers ----
green() { echo -e "\033[32m$*\033[0m"; }
yellow() { echo -e "\033[33m$*\033[0m"; }
blue()  { echo -e "\033[34m$*\033[0m"; }

# =============================================================================
# 2A PROOFS
# =============================================================================
blue "
=== 2A PROOFS: CloudFront path and origin cloaking ==="

# 2A-1: CloudFront -> 200
# This proves your domain is reachable through CloudFront.
echo ""
yellow "2A-1: CloudFront -> 200 (you should see HTTP/2 200)"
curl -sI "$CF_URL" | tee "$PROOF_2A/app_via_domain_headers.txt"
green "  Saved -> $PROOF_2A/app_via_domain_headers.txt"

# 2A-2: ALB direct -> 403
# This proves origin cloaking: the ALB blocks anything that didn't come through
# CloudFront (no X-Chewbacca-Growl header = 403 Fixed Response).
echo ""
yellow "2A-2: ALB direct -> 403 (you should see 403 Forbidden)"
curl -sI "http://$ALB_DNS" | tee "$PROOF_2A/alb_direct_headers.txt"
green "  Saved -> $PROOF_2A/alb_direct_headers.txt"

# 2A-3: dig to confirm DNS -> CloudFront (not ALB IP)
echo ""
yellow "2A-3: DNS check (you should see CloudFront IPs, not ALB IPs)"
dig "$CF_URL" A +short | head -5 | tee "$PROOF_2A/dig_cf_proof.txt"
green "  Saved -> $PROOF_2A/dig_cf_proof.txt"

# =============================================================================
# 2B DELIVERABLE D.1 — Static caching (run twice, Age should increase)
# =============================================================================
blue "
=== 2B D.1: Static caching — two requests, Age should go up ==="

echo ""
yellow "D.1-1: First request to /static/example.txt"
curl -sI "$CF_URL/static/example.txt" | tee "$PROOF_2B/proof-static-example-1.txt"
green "  Saved -> proof-static-example-1.txt"

echo ""
yellow "  Waiting 5 seconds so Age increases on second request..."
sleep 5

yellow "D.1-2: Second request to /static/example.txt (Age should be higher)"
curl -sI "$CF_URL/static/example.txt" | tee "$PROOF_2B/proof-static-example-2.txt"
green "  Saved -> proof-static-example-2.txt"

echo ""
echo "  What to look for:"
echo "    x-cache: Hit from cloudfront  <- object was served from edge cache"
echo "    age: N                         <- N = seconds since it was cached"
echo "    Cache-Control: public, max-age=86400  <- from the response headers policy"

# =============================================================================
# 2B DELIVERABLE D.2 — API must NOT cache (run twice, no Age header)
# =============================================================================
blue "
=== 2B D.2: API cache safety — two requests, no Age header ==="

echo ""
yellow "D.2-1: First request to /api/list"
curl -sI "$CF_URL/api/list" | tee "$PROOF_2B/proof-api-list-1.txt"
green "  Saved -> proof-api-list-1.txt"

sleep 2

yellow "D.2-2: Second request to /api/list (still no Age, not cached)"
curl -sI "$CF_URL/api/list" | tee "$PROOF_2B/proof-api-list-2.txt"
green "  Saved -> proof-api-list-2.txt"

echo ""
echo "  What to look for:"
echo "    NO 'age:' header               <- means nothing was cached at the edge"
echo "    Cache-Control: private, no-store <- origin is telling CF not to cache (after app patch)"
echo "    x-cache: Miss from cloudfront  <- every request goes all the way to origin"

# =============================================================================
# 2B DELIVERABLE D.3 — Query string sanity
# Two different query strings -> same cached object
# =============================================================================
blue "
=== 2B D.3: Query string sanity — ?v=1 and ?v=2 should hit same cache ==="

echo ""
yellow "D.3-1: /static/example.txt?v=1"
curl -sI "$CF_URL/static/example.txt?v=1" | tee "$PROOF_2B/proof-query-string-v1.txt"
green "  Saved -> proof-query-string-v1.txt"

sleep 2

yellow "D.3-2: /static/example.txt?v=2"
curl -sI "$CF_URL/static/example.txt?v=2" | tee "$PROOF_2B/proof-query-string-v2.txt"
green "  Saved -> proof-query-string-v2.txt"

echo ""
echo "  What to look for:"
echo "    Both show: x-cache: Hit from cloudfront"
echo "    Both show similar Age values    <- same cache object, query string stripped"
echo "    This proves: static cache policy ignores query strings (path-only key)"

# =============================================================================
# ManA VERIFICATION — /api/public-feed: Miss -> Hit -> Miss
#
# This is the Honors A proof. Three requests spread over ~70 seconds.
# The s-maxage=30 means CloudFront should hold it for 30s then expire.
# =============================================================================
blue "
=== ManA: public-feed Miss -> Hit -> Miss sequence ==="

echo ""
yellow "ManA-1: First request (expect: Miss from cloudfront)"
curl -si "$CF_URL/api/public-feed" | grep -E "^(HTTP|cache-control|age|x-cache|via)" | tee "$PROOF_2B/proof-mana-public-feed-1-miss.txt"
green "  Saved -> proof-mana-public-feed-1-miss.txt"

echo ""
yellow "  Waiting 10 seconds (still within the 30s cache window)..."
sleep 10

yellow "ManA-2: Second request (expect: Hit from cloudfront, age > 0)"
curl -si "$CF_URL/api/public-feed" | grep -E "^(HTTP|cache-control|age|x-cache|via)" | tee "$PROOF_2B/proof-mana-public-feed-2-hit.txt"
green "  Saved -> proof-mana-public-feed-2-hit.txt"

echo ""
yellow "  Waiting 35 seconds for the 30s TTL to expire..."
sleep 35

yellow "ManA-3: Third request (expect: Miss again — TTL expired, fresh fetch)"
curl -si "$CF_URL/api/public-feed" | grep -E "^(HTTP|cache-control|age|x-cache|via)" | tee "$PROOF_2B/proof-mana-public-feed-3-miss-again.txt"
green "  Saved -> proof-mana-public-feed-3-miss-again.txt"

echo ""
echo "  What to look for:"
echo "    Request 1: x-cache: Miss from cloudfront"
echo "    Request 2: x-cache: Hit from cloudfront, age: 10 (or similar)"
echo "    Request 3: x-cache: Miss from cloudfront (TTL expired)"

# =============================================================================
# ManA VERIFICATION — /api/list must NEVER cache
# =============================================================================
blue "
=== ManA: /api/list never cached proof ==="

echo ""
yellow "ManA-4: /api/list — should show private,no-store and no Hit"
curl -si "$CF_URL/api/list" | grep -E "^(HTTP|cache-control|age|x-cache|via)" | tee "$PROOF_2B/proof-mana-api-list-nocache.txt"
green "  Saved -> proof-mana-api-list-nocache.txt"

echo ""
echo "  What to look for:"
echo "    Cache-Control: private, no-store  <- origin is saying 'never cache this'"
echo "    NO age: header                     <- confirming nothing was cached"

# =============================================================================
# DONE
# =============================================================================
blue "
=============================================================================
PROOF CAPTURE COMPLETE
=============================================================================
"
echo "Files written:"
echo ""
echo "  2A proofs (origin cloaking + DNS):"
echo "    $PROOF_2A/app_via_domain_headers.txt"
echo "    $PROOF_2A/alb_direct_headers.txt"
echo "    $PROOF_2A/dig_cf_proof.txt"
echo ""
echo "  2B proofs (cache behaviors):"
echo "    $PROOF_2B/proof-static-example-1.txt"
echo "    $PROOF_2B/proof-static-example-2.txt"
echo "    $PROOF_2B/proof-api-list-1.txt"
echo "    $PROOF_2B/proof-api-list-2.txt"
echo "    $PROOF_2B/proof-query-string-v1.txt"
echo "    $PROOF_2B/proof-query-string-v2.txt"
echo ""
echo "  ManA proofs (origin-driven caching):"
echo "    $PROOF_2B/proof-mana-public-feed-1-miss.txt"
echo "    $PROOF_2B/proof-mana-public-feed-2-hit.txt"
echo "    $PROOF_2B/proof-mana-public-feed-3-miss-again.txt"
echo "    $PROOF_2B/proof-mana-api-list-nocache.txt"
echo ""
echo "Next steps:"
echo "  1. Run the gate scripts: ./Lab2/run_all_gates_commands.sh"
echo "  2. Run terraform apply in Lab2/Lab2A/ if not done yet"
echo "  3. Review proof files and check the expected values match"
