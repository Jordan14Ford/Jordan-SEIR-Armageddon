# Pre-submission Checklist

## Files

- [ ] `00_architecture-summary.md` — makes sense, no contradictions
- [ ] `01_data-residency-proof.txt` — CLI output is current
- [ ] `02_edge-proof-cloudfront.txt` — live evidence present
- [ ] `03_waf-proof.txt` — live evidence present
- [ ] `04_cloudtrail-change-proof.txt` — events present
- [ ] `05_network-corridor-proof.txt` — TGW and route table proof present
- [ ] `06_auditor-narrative.md` — no contradictions with evidence
- [ ] `evidence.json` — resource IDs match what's deployed
- [ ] `README-submission-note.md` — file list is accurate

## Live verification (run after environment is up)

```bash
# RDS only in Tokyo
aws rds describe-db-instances --region ap-northeast-1 \
  --query 'DBInstances[].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}' \
  --output table

aws rds describe-db-instances --region sa-east-1 \
  --query 'DBInstances[].DBInstanceIdentifier' \
  --output table

# Route tables have TGW routes
aws ec2 describe-route-tables --region ap-northeast-1 \
  --filters "Name=tag:Name,Values=*private*" \
  --query 'RouteTables[].Routes[*].[DestinationCidrBlock,TransitGatewayId]' \
  --output table

aws ec2 describe-route-tables --region sa-east-1 \
  --filters "Name=tag:Name,Values=*private*" \
  --query 'RouteTables[].Routes[*].[DestinationCidrBlock,TransitGatewayId]' \
  --output table

# São Paulo app points to Tokyo RDS
curl http://lab3-sao-paulo-alb-732953206.sa-east-1.elb.amazonaws.com/
```

## Before submitting

- [ ] No credentials or secrets in any file
- [ ] File names match what's listed in README-submission-note.md
- [ ] Nothing references CloudFront or WAF as "planned" — both are live
