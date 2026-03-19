# 2A Architecture Summary

High-level architecture and design choices for Lab 2A (CloudFront, WAF, ALB, origin cloaking).

---

## Architecture (intended)

```
Viewer (HTTPS)
    → CloudFront (custom domain apex + app, WAF attached)
    → ALB (HTTPS, custom header required; SG allows only CloudFront prefix list)
    → EC2 (Flask app)
```

- **Route 53:** Apex and `app.` are A (alias) records to CloudFront, not to the ALB.
- **Origin cloaking:** (1) ALB SG allows only CloudFront prefix list. (2) Listener rule forwards only when custom header matches; otherwise default action (e.g. 403).

---

## Path-based behaviors (CloudFront)

- `/api/public-feed` — origin-driven cache (managed policy).
- `/api/*` — no cache (custom cache + origin request policy).
- `/static/*` — aggressive cache (custom policy); optional response headers policy for Cache-Control.
- Default — caching disabled.

---

## Key Terraform (location)

All 2A (and shared 2B) Terraform lives under **LAB2/2a/src/terraform/**:

- CloudFront distribution, behaviors, WAF: `lab2_cloudfront_alb.tf`, `lab2_cloudfront_shield_waf.tf`
- Route 53: `lab2_cloudfront_r53.tf`
- ALB SG + listener rule: `lab2_cloudfront_origin_cloaking.tf`
- Cache/origin-request policies (2B): `lab2b_cache_policies.tf`, `lab2b_honors_origin_driven.tf`, `lab2b_response_headers_policy.tf`

---

## More detail

- **Lab2A_Verification_and_Submission_Readiness_Report.md** (in this folder) — Full verification and submission notes.
- **notes/** — 2a completion checklist, deliverables index, proof map.
