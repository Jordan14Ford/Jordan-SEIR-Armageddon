# Lab 2 — Gate Outputs (Canonical Location)

Automated gate run outputs live under:

**Path:** `Lab2/Lab2A/deliverables/verification/gates/`

| File | Gate | Typical result |
|------|------|----------------|
| `gate_network_db_run.txt` | Network + RDS | FAIL (VPC mismatch EC2 vs RDS) |
| `gate_secrets_run.txt` | Secrets + IAM role | PASS |
| `gate_cf_alb_run.txt` | CloudFront + ALB infra | FAIL (WAF/Route53/logging strictness) |
| `gate_cache_run.txt` | Cache policy modernity | FAIL (same as above) |
| `GATE_SUMMARY.md` | Explanation of each failure | READY |

Details and whether failures are blocking are in **Lab2A/deliverables/verification/gates/GATE_SUMMARY.md** and **docs/REMAINING_GAPS_CHECKLIST.md**.
