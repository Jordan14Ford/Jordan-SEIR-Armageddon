#!/bin/bash
REGION=us-east-1
WAF_LOG_GROUP=aws-waf-logs-cloudyjones-webacl01
APP_LOG_GROUP=/aws/ec2/cloudyjones-rds-app
START=$(date -v-15M +%s 2>/dev/null || date -d '15 minutes ago' +%s)
END=$(date +%s)

run_query() {
  local name=$1
  local log_group=$2
  local query=$3
  
  echo "Running: $name"
  QID=$(aws logs start-query \
    --log-group-name "$log_group" \
    --start-time $START \
    --end-time $END \
    --query-string "$query" \
    --region $REGION \
    --query 'queryId' \
    --output text)
  
  sleep 5
  
  aws logs get-query-results \
    --query-id $QID \
    --region $REGION > ~/Desktop/TWC/Lab1C-V2/evidence/section-f/${name}.json
  
  echo "Saved: ${name}.json"
}

# WAF Queries
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

echo "All WAF queries complete"
