# Lab 2 — Final Submission Map

**This copy is under `SEIR_Foundations/LAB2/`.** Paths below use the new layout (2a/, 2b/).

👉 **Graders start here:** [GRADER_START_HERE.md](GRADER_START_HERE.md) (or [docs/GRADER_START_HERE.md](docs/GRADER_START_HERE.md)).

👉 **Submission checklist:** This file — every Terraform file, proof file, written explanation, gate output, and live-vs-repo note with **status: ready / partial / pending**.

- **Full index:** [DELIVERABLES_INDEX.md](DELIVERABLES_INDEX.md) — what each deliverable proves and its status.  
- **Remaining gaps:** [REMAINING_GAPS_CHECKLIST.md](REMAINING_GAPS_CHECKLIST.md).  
- **Evidence-based report:** [LAB2_REMAINING_WORK_REPORT.md](LAB2_REMAINING_WORK_REPORT.md).

---

## Terraform

| Filename | Purpose | Status |
|----------|---------|--------|
| `SEIR_Foundations/LAB2/2a/src/terraform/lab2_cloudfront_alb.tf` | CloudFront distribution, behaviors | ready |
| `SEIR_Foundations/LAB2/2a/src/terraform/lab2_cloudfront_origin_cloaking.tf` | ALB SG + listener rule (origin cloaking) | ready |
| `SEIR_Foundations/LAB2/2a/src/terraform/lab2_cloudfront_r53.tf` | Route53 A alias records | ready |
| `SEIR_Foundations/LAB2/2a/src/terraform/lab2_cloudfront_shield_waf.tf` | WAF WebACL CLOUDFRONT | ready |
| `SEIR_Foundations/LAB2/2a/src/terraform/lab2b_cache_policies.tf` | Cache + origin request policies | ready |
| `SEIR_Foundations/LAB2/2a/src/terraform/lab2b_response_headers_policy.tf` | RHP: Cache-Control on /static/* (Be A Man A.4) | ready |
| `SEIR_Foundations/LAB2/2a/src/terraform/lab2b_honors_origin_driven.tf` | UseOriginCacheControlHeaders (ManA) | ready |
| `Lab1/Lab1C-V2/ec2.tf` | Flask app with 2B routes + ETag (ManA, ManC) | ready |

---

## Proof — 2A

| Filename | Purpose | Status |
|----------|---------|--------|
| `SEIR_Foundations/LAB2/2a/deliverables/verification/curl_checks/proof1-cf-apex-200.txt` | 200 via CloudFront (apex) | ready |
| `SEIR_Foundations/LAB2/2a/deliverables/verification/curl_checks/proof2-cf-app-200.txt` | 200 via CloudFront (app) | ready |
| `SEIR_Foundations/LAB2/2a/deliverables/verification/curl_checks/proof3-dig-cloudfront-ips.txt` | DNS → CloudFront | ready |
| `SEIR_Foundations/LAB2/2a/deliverables/verification/aws_checks/proof4-cf-config.json` | CF config | ready |
| `SEIR_Foundations/LAB2/2a/deliverables/verification/aws_checks/proof5-waf-cloudfront-scope.json` | WAF scope | ready |
| `SEIR_Foundations/LAB2/2a/deliverables/verification/curl_checks/alb_direct_blocked.txt` | ALB direct blocked (timeout) | ready |
| `SEIR_Foundations/LAB2/2a/deliverables/verification/curl_checks/dig_cf_proof.txt` | CNAME to CloudFront | ready |

---

## Proof — 2B (core + Be A Man)

| Filename | Purpose | Status |
|----------|---------|--------|
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-static-example-1.txt` | Static Hit #1 | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-static-example-2.txt` | Static Hit #2, Age increases | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-static-qs-v1.txt` | ?v=1 cache key | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-static-qs-v2.txt` | ?v=2 same object | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-api-list-1.txt` | /api/list no cache | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-api-list-2.txt` | /api/list no cache #2 | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-public-feed-miss.txt` | public-feed Miss | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-public-feed-hit.txt` | public-feed Hit, Age | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-invalidation-before.txt` | Hit before invalidation | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-invalidation-after.txt` | Miss after invalidation | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-invalidation-record.json` | Invalidation ID | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-invalidation-example-record.json` | Invalidation /static/example.txt | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-manc-miss.txt` | Miss with ETag, Last-Modified | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-manc-hit.txt` | Hit with ETag | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-manc-304.txt` | 304 conditional request | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/verification/proof-manc-refreshhit.txt` | *(Shows Hit; literal RefreshHit not required for pass)* | partial |

---

## Written explanations (2B)

| Filename | Purpose | Status |
|----------|---------|--------|
| `SEIR_Foundations/LAB2/2b/deliverables/architecture/2b_cache_explanation.txt` | Cache key / forward (Core B.B) | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/architecture/chewbacca_haiku.txt` | Haiku 漢字 (Core C) | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/architecture/2b_honors_paragraph.txt` | Origin-driven (ManA) | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/architecture/2b_manb_invalidation_policy.txt` | Invalidate vs version (ManB) | ready |
| `SEIR_Foundations/LAB2/2b/deliverables/architecture/2b_manc_refreshhit_explanation.txt` | RefreshHit (ManC) | ready |

---

## Gate outputs (2A)

| Filename | Purpose | Status |
|----------|---------|--------|
| `SEIR_Foundations/LAB2/2a/deliverables/verification/gates/gate_network_db_run.txt` | Network + RDS | ready (FAIL: VPC) |
| `SEIR_Foundations/LAB2/2a/deliverables/verification/gates/gate_secrets_run.txt` | Secrets + IAM | ready (PASS) |
| `SEIR_Foundations/LAB2/2a/deliverables/verification/gates/gate_cf_alb_run.txt` | CF + ALB | ready (FAIL: strictness) |
| `SEIR_Foundations/LAB2/2a/deliverables/verification/gates/gate_cache_run.txt` | Cache policy | ready (FAIL: strictness) |
| `SEIR_Foundations/LAB2/2a/deliverables/verification/gates/GATE_SUMMARY.md` | Explanation of failures | ready |

---

## Live vs repo state

| Note | Status |
|------|--------|
| **Live domain for proof:** app.cloudyjones.xyz | — |
| App routes and ETag in repo (Lab1/Lab1C-V2/ec2.tf); live was patched via SSM; new instances get user_data | Synced |
| Origin protocol: Terraform uses http-only (CF→ALB); apply has been run | ready |
| /api/list returns 500 (DB unreachable, VPC mismatch); cache-safety proven via headers and x-cache: Error | documented |

---

## Submission readiness

| Section | Status |
|---------|--------|
| Core 2A Terraform + proof | ready |
| Core 2B Terraform + proof + docs | ready |
| Be A Man A.4, ManA, ManB, ManC | ready (ManC literal RefreshHit optional) |
| Gates | run; 1 PASS, 3 FAIL (documented) |
| **Overall** | **Ready for submission** — required deliverables and Be A Man items are present. Optional gaps in REMAINING_GAPS_CHECKLIST.md. |
