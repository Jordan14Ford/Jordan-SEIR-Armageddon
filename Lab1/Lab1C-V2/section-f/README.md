# Bonus-F — CloudWatch Logs Insights Query Pack

No Terraform resources live here. Bonus-F is a query and analysis exercise
run against live CloudWatch log groups created in other sections.

## Log groups used
| Log group | Created by |
|---|---|
| `/aws/ec2/cloudyjones-rds-app` | `modules/core/rds.tf` |
| `aws-waf-logs-cloudyjones-webacl01` | `modules/section-e/waf_logging.tf` |

## Run queries
```bash
cd evidence/
bash run_queries.sh
```

## Evidence files
| File | Query |
|---|---|
| `evidence/A1-top-actions.json` | WAF — ALLOW vs BLOCK counts |
| `evidence/A2-top-client-ips.json` | WAF — top 25 source IPs |
| `evidence/A3-top-uris.json` | WAF — top 25 requested URIs |
| `evidence/A4-blocked-requests.json` | WAF — blocked IP+URI pairs |
| `evidence/A5-blocking-rules.json` | WAF — which rules are firing |

## Correlation workflow (incident triage)
1. Run A1 — if BLOCK count spikes → external pressure, check A4+A5
2. Run A1 — if WAF is quiet but app errors spike → backend failure (RDS/SG/creds)
3. Check app log group with Insights query: `fields @timestamp, @message | filter @message like /ERROR|db|timeout/i | sort @timestamp desc | limit 30`
4. Cross-reference with CloudWatch alarm state in `modules/core/rds.tf` (DBConnectionErrors alarm)
