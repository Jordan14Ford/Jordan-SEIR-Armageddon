# 2A Verification Summary

One-page summary of verification artifacts for Lab 2A (CloudFront, WAF, Route 53, ALB).

---

## Verification layout

| Folder | Contents |
|--------|----------|
| **curl_checks/** | curl/dig proof: apex 200, app 200, ALB blocked, DNS → CloudFront |
| **aws_checks/** | AWS CLI output: CloudFront config, WAF, Route 53, ALB listings |
| **gates/** | Automated gate runs: JSON, badge, run logs, GATE_SUMMARY.md |
| **cli/** | Other raw CLI proof (if any) |

---

## Proof files (quick reference)

- **HTTP 200 via CloudFront (apex, app):** `curl_checks/proof1-cf-apex-200.txt`, `proof2-cf-app-200.txt`
- **DNS → CloudFront:** `curl_checks/proof3-dig-cloudfront-ips.txt`, `dig_cf_proof.txt`
- **Direct ALB blocked:** `curl_checks/alb_direct_blocked.txt`
- **CloudFront / WAF config:** `aws_checks/proof4-cf-config.json`, `proof5-waf-cloudfront-scope.json`
- **Gate results:** `gates/gate_*_result.json`, `gate_*_run.txt`, `GATE_SUMMARY.md`

---

## Gate status (at last run)

See **gates/GATE_SUMMARY.md** for full detail. Summary:

- **Secrets + IAM:** PASS
- **Network/RDS:** FAIL (VPC mismatch; documented)
- **CloudFront + ALB / Cache:** FAIL (strictness; documented)

---

## TODO / placeholders

- If any verification artifact is missing, add a file here with a short `TODO: capture ...` and the command to run.
