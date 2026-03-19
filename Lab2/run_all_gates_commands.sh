#!/usr/bin/env bash
# =============================================================================
# run_all_gates_commands.sh
#
# Runs all 4 SEIR gate scripts with your real AWS values pre-filled.
# Gates are the automated graders the instructor uses to verify your work.
# Each one checks a different layer of the stack and writes a gate_result.json.
#
# BEFORE RUNNING THIS:
#   1. Make sure you have AWS CLI configured with your credentials
#   2. Replace the two FILL_ME values at the top (RDS ID and Secret ID)
#   3. Run from the repo root:
#        chmod +x Lab2/run_all_gates_commands.sh
#        ./Lab2/run_all_gates_commands.sh
#
# What each gate checks:
#   Gate 1 (lab2_alb)     - CloudFront, WAF, Route53, ACM, ALB, SG — the full CF stack
#   Gate 2 (network_db)   - EC2 <-> RDS network: RDS not public, SG-to-SG rule exists
#   Gate 3 (secrets_role) - Secrets Manager exists, EC2 has IAM role attached
#   Gate 4 (cloudfront)   - CloudFront cache policy is modern (not legacy ForwardedValues)
#
# Output: gate_result.json, badge.txt, pr_comment.md in each gate's output folder
# Badge: GREEN = full pass, YELLOW = pass with warnings, RED = failed checks
# =============================================================================

set -euo pipefail

# ============================================================
# YOUR REAL VALUES (pre-filled from existing proof files)
# ============================================================
CF_DISTRIBUTION_ID="EOCU676C9I3FL"
DOMAIN_NAME="cloudyjones.xyz"
ROUTE53_ZONE_ID="Z01825573SNDEWHMXEY94"
ACM_CERT_ARN="arn:aws:acm:us-east-1:583001104385:certificate/4d5ab9d8-dc03-405c-8129-c7f0fbb30b4f"
WAF_WEB_ACL_ARN="arn:aws:wafv2:us-east-1:583001104385:global/webacl/cloudyjones-cf-webacl01/8bdb58a8-bc6a-4830-9ca1-74bbd79ab426"
ALB_ARN="arn:aws:elasticloadbalancing:us-east-1:583001104385:loadbalancer/app/cloudyjones-alb01/787859777f179c9e"
ALB_SG_ID="sg-0721435774b98e5d3"
INSTANCE_ID="i-06003411f26d02bef"
REGION="us-east-1"

# ---- YOU MUST FILL THESE TWO IN ----
# Find your RDS identifier:
#   aws rds describe-db-instances --region us-east-1 --query "DBInstances[].DBInstanceIdentifier" --output text
DB_ID="${DB_ID:-FILL_ME_RDS_INSTANCE_ID}"

# Find your secret name:
#   aws secretsmanager list-secrets --region us-east-1 --query "SecretList[].Name" --output text
SECRET_ID="${SECRET_ID:-FILL_ME_SECRET_NAME}"

# ============================================================
# Output folders
# ============================================================
GATE_OUT="Lab2/Lab2A/deliverables/verification/gates"
mkdir -p "$GATE_OUT"

SEIR_PYTHON="Lab2/SEIR files/LAB2/python"

green() { echo -e "\033[32m$*\033[0m"; }
yellow() { echo -e "\033[33m$*\033[0m"; }
blue()  { echo -e "\033[34m$*\033[0m"; }
red()   { echo -e "\033[31m$*\033[0m"; }

# ============================================================
# GATE 1: Full CloudFront + ALB gate
# Checks: CF enabled/deployed, aliases, ACM, WAF, Route53, ALB scheme,
#         ALB listeners, SG not world-open, CF origin = ALB DNS
# ============================================================
blue "
=== GATE 1: CloudFront + ALB infrastructure gate ==="
yellow "  This is the big one. Checks your entire 2A stack automatically."
echo ""

ORIGIN_REGION="$REGION" \
CF_DISTRIBUTION_ID="$CF_DISTRIBUTION_ID" \
DOMAIN_NAME="$DOMAIN_NAME" \
ROUTE53_ZONE_ID="$ROUTE53_ZONE_ID" \
ACM_CERT_ARN="$ACM_CERT_ARN" \
WAF_WEB_ACL_ARN="$WAF_WEB_ACL_ARN" \
ALB_ARN="$ALB_ARN" \
ALB_SG_ID="$ALB_SG_ID" \
REQUIRE_ALB_INTERNAL="false" \
OUT_JSON="$GATE_OUT/gate1_cf_alb_result.json" \
BADGE_TXT="$GATE_OUT/gate1_badge.txt" \
PR_COMMENT_MD="$GATE_OUT/gate1_pr_comment.md" \
bash "$SEIR_PYTHON/run_all_gates_lab2_alb.sh" || true

green "  Gate 1 done. Badge: $(cat $GATE_OUT/gate1_badge.txt 2>/dev/null || echo 'see gate1_cf_alb_result.json')"
echo "  Results: $GATE_OUT/gate1_cf_alb_result.json"

# ============================================================
# GATE 2: EC2 <-> RDS network gate
# Checks: RDS not publicly accessible, SG-to-SG rule from EC2 to RDS on DB port
# ============================================================
blue "
=== GATE 2: EC2 <-> RDS network gate ==="
yellow "  Verifies RDS is private and EC2 can reach it through security groups."
echo ""

if [[ "$DB_ID" == "FILL_ME_RDS_INSTANCE_ID" ]]; then
  red "  SKIPPED: Set DB_ID env var or edit this script. Run:"
  echo "  aws rds describe-db-instances --query 'DBInstances[].DBInstanceIdentifier' --output text"
else
  REGION="$REGION" \
  INSTANCE_ID="$INSTANCE_ID" \
  DB_ID="$DB_ID" \
  OUT_JSON="$GATE_OUT/gate2_network_db_result.json" \
  bash "$SEIR_PYTHON/gate_network_db.sh" || true

  echo "  Results: $GATE_OUT/gate2_network_db_result.json"
fi

# ============================================================
# GATE 3: Secrets Manager + IAM role gate
# Checks: secret exists, EC2 has instance profile, role resolved
# ============================================================
blue "
=== GATE 3: Secrets Manager + EC2 role gate ==="
yellow "  Verifies your instance can access secrets and has the right IAM role."
echo ""

if [[ "$SECRET_ID" == "FILL_ME_SECRET_NAME" ]]; then
  red "  SKIPPED: Set SECRET_ID env var or edit this script. Run:"
  echo "  aws secretsmanager list-secrets --query 'SecretList[].Name' --output text"
else
  REGION="$REGION" \
  INSTANCE_ID="$INSTANCE_ID" \
  SECRET_ID="$SECRET_ID" \
  OUT_JSON="$GATE_OUT/gate3_secrets_role_result.json" \
  bash "$SEIR_PYTHON/gate_secrets_and_role.sh" || true

  echo "  Results: $GATE_OUT/gate3_secrets_role_result.json"
fi

# ============================================================
# GATE 4: CloudFront cache policy modernity check (original gate)
# Checks: CF uses CachePolicyId (modern), not legacy ForwardedValues
# ============================================================
blue "
=== GATE 4: CloudFront legacy vs modern cache config gate ==="
yellow "  Checks that your distribution uses modern CachePolicyId, not the old ForwardedValues."
echo ""

ORIGIN_REGION="$REGION" \
CF_DISTRIBUTION_ID="$CF_DISTRIBUTION_ID" \
DOMAIN_NAME="$DOMAIN_NAME" \
ROUTE53_ZONE_ID="$ROUTE53_ZONE_ID" \
ACM_CERT_ARN="$ACM_CERT_ARN" \
WAF_WEB_ACL_ARN="$WAF_WEB_ACL_ARN" \
ORIGIN_SG_ID="$ALB_SG_ID" \
OUT_JSON="$GATE_OUT/gate4_cf_result.json" \
BADGE_TXT="$GATE_OUT/gate4_badge.txt" \
PR_COMMENT_MD="$GATE_OUT/gate4_pr_comment.md" \
bash "$SEIR_PYTHON/run_all_gates.sh" || true

green "  Gate 4 done. Badge: $(cat $GATE_OUT/gate4_badge.txt 2>/dev/null || echo 'see gate4_cf_result.json')"
echo "  Results: $GATE_OUT/gate4_cf_result.json"

# ============================================================
# SUMMARY
# ============================================================
blue "
=============================================================================
ALL GATES DONE
=============================================================================
"
echo "Results folder: $GATE_OUT/"
echo ""
echo "Badges:"
for f in "$GATE_OUT"/gate*_badge.txt; do
  [[ -f "$f" ]] && echo "  $(basename $f): $(cat $f)"
done
echo ""
echo "To see failures for any gate:"
echo "  cat $GATE_OUT/gate1_cf_alb_result.json | python3 -m json.tool | grep -A5 'failures'"
echo ""
echo "GREEN = pass, YELLOW = pass with warnings, RED = has failures to fix"
