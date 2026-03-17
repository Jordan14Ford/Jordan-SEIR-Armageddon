# Audit Pack — What's in here

This folder has everything needed to verify the Lab 3 architecture from a compliance standpoint.

| File | What it is |
|---|---|
| `00_architecture-summary.md` | Overview of how the system works |
| `01_data-residency-proof.txt` | CLI output proving RDS only exists in Tokyo |
| `02_edge-proof-cloudfront.txt` | Live evidence of CloudFront distribution |
| `03_waf-proof.txt` | Live evidence of WAF deployment |
| `04_cloudtrail-change-proof.txt` | CloudTrail events — who changed what |
| `05_network-corridor-proof.txt` | TGW attachments, route tables, health checks |
| `06_auditor-narrative.md` | Plain-language summary for a reviewer |
| `evidence.json` | Key resource IDs and claims in machine-readable form |

All evidence files are live — captured from the running environment in March 2026.

The core claims:
1. RDS exists only in Tokyo
2. São Paulo and Osaka have no database
3. Cross-region traffic goes through Transit Gateway, not the public internet
4. CloudFront is the only public entry point
5. WAF blocks unauthorized access at the edge and on the ALB
6. All infrastructure changes are logged in CloudTrail
