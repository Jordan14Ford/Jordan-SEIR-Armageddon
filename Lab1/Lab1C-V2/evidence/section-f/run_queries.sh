#!/bin/bash
set -euo pipefail

REGION=us-east-1
WAF_LOG_GROUP=aws-waf-logs-cloudyjones-webacl01
APP_LOG_GROUP=/aws/ec2/cloudyjones-rds-app
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

START=$(date -v-15M +%s 2>/dev/null || date -d '15 minutes ago' +%s)
END=$(date +%s)

run_query() {
  local name=$1
  local log_group=$2
  local query=$3

  echo "Running: $name against $log_group"
  QID=$(aws logs start-query \
    --log-group-name "$log_group" \
    --start-time "$START" \
    --end-time "$END" \
    --query-string "$query" \
    --region "$REGION" \
    --query 'queryId' \
    --output text)

  sleep 5

  aws logs get-query-results \
    --query-id "$QID" \
    --region "$REGION" > "${SCRIPT_DIR}/${name}.json"

  echo "Saved: ${name}.json"
}

echo "============================================"
echo "  Section F — Logs Insights Query Pack"
echo "  WAF log group: $WAF_LOG_GROUP"
echo "  App log group: $APP_LOG_GROUP"
echo "  Window: last 15 minutes"
echo "============================================"

# ---- WAF Queries (A series) ----

run_query "A1-top-actions" "$WAF_LOG_GROUP" \
  "fields @timestamp, action | stats count() as hits by action | sort hits desc"

run_query "A2-top-client-ips" "$WAF_LOG_GROUP" \
  "fields @timestamp, httpRequest.clientIp as clientIp | stats count() as hits by clientIp | sort hits desc | limit 25"

run_query "A3-top-uris" "$WAF_LOG_GROUP" \
  "fields @timestamp, httpRequest.uri as uri | stats count() as hits by uri | sort hits desc | limit 25"

run_query "A4-blocked-requests" "$WAF_LOG_GROUP" \
  "fields @timestamp, action, httpRequest.clientIp as clientIp, httpRequest.uri as uri | filter action = 'BLOCK' | stats count() as blocks by clientIp, uri | sort blocks desc | limit 25"

run_query "A5-blocking-rules" "$WAF_LOG_GROUP" \
  "fields @timestamp, action, terminatingRuleId, terminatingRuleType | filter action = 'BLOCK' | stats count() as blocks by terminatingRuleId, terminatingRuleType | sort blocks desc | limit 25"

echo ""
echo "WAF queries complete."
echo ""

# ---- App Queries (B series) ----

run_query "B1-error-rate-over-time" "$APP_LOG_GROUP" \
  "fields @timestamp, @message | filter @message like /ERROR|Exception|Traceback|DB|timeout|refused/i | stats count() as errors by bin(1m) | sort bin(1m) asc"

run_query "B2-recent-db-failures" "$APP_LOG_GROUP" \
  "fields @timestamp, @message | filter @message like /DB|mysql|timeout|refused|Access denied|could not connect/i | sort @timestamp desc | limit 50"

run_query "B3-failure-classifier" "$APP_LOG_GROUP" \
  "fields @timestamp, @message | filter @message like /Access denied|authentication failed|timeout|refused|no route|could not connect/i | stats count() as hits by case(@message like /Access denied|authentication failed/i, 'Creds_Auth', @message like /timeout|no route/i, 'Network_Route', @message like /refused/i, 'Port_SG_Refused', 'Other') as category | sort hits desc"

echo ""
echo "App queries complete."
echo ""

# ---- Correlation Workflow ----
echo "============================================"
echo "  Correlation Workflow"
echo "============================================"
echo "1) Check B1 error-rate-over-time → does it spike at the alarm time?"
echo "2) Check A1 top-actions → if BLOCK spikes align → external pressure"
echo "   If WAF quiet but B1 spikes → backend (RDS/SG/creds)"
echo "3) If backend suspected → check B3 classifier:"
echo "   Creds_Auth → secrets drift / wrong password"
echo "   Network_Route → SG/routing/RDS down"
echo "4) Retrieve known-good values:"
echo "   aws ssm get-parameters --names /lab/db/endpoint /lab/db/port /lab/db/name --with-decryption"
echo "   aws secretsmanager get-secret-value --secret-id lab/rds/mysql"
echo "5) Verify recovery: curl https://app.cloudyjones.xyz/list"
echo "   B1 errors return to baseline, alarm returns to OK"
echo "============================================"
echo ""
echo "All queries complete."
