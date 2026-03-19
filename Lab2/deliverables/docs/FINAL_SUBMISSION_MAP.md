# Lab 2 — Final Submission Map

Single checklist for submission. Each entry: filename, purpose, status (ready / partial / pending). Paths relative to repo root.

---

## Terraform

| Filename | Purpose | Status |
|----------|---------|--------|
| `Lab2/Lab2A/lab2_cloudfront_alb.tf` | CloudFront distribution, behaviors | ready |
| `Lab2/Lab2A/lab2_cloudfront_origin_cloaking.tf` | ALB SG + listener rule (origin cloaking) | ready |
| `Lab2/Lab2A/lab2_cloudfront_r53.tf` | Route53 A alias records | ready |
| `Lab2/Lab2A/lab2_cloudfront_shield_waf.tf` | WAF WebACL CLOUDFRONT | ready |
| `Lab2/Lab2A/lab2b_cache_policies.tf` | Cache + origin request policies | ready |
| `Lab2/Lab2A/lab2b_response_headers_policy.tf` | RHP: Cache-Control on /static/* (Be A Man A.4) | ready |
| `Lab2/Lab2A/lab2b_honors_origin_driven.tf` | UseOriginCacheControlHeaders (ManA) | ready |
| `Lab1/Lab1C-V2/ec2.tf` | Flask app with 2B routes + ETag (ManA, ManC) | ready |

---

## Proof — 2A

| Filename | Purpose | Status |
|----------|---------|--------|
| `Lab2/Lab2A/deliverables/proof/proof1-cf-apex-200.txt` | 200 via CloudFront (apex) | ready |
| `Lab2/Lab2A/deliverables/proof/proof2-cf-app-200.txt` | 200 via CloudFront (app) | ready |
| `Lab2/Lab2A/deliverables/proof/proof3-dig-cloudfront-ips.txt` | DNS → CloudFront | ready |
| `Lab2/Lab2A/deliverables/proof/proof4-cf-config.json` | CF config | ready |
| `Lab2/Lab2A/deliverables/proof/proof5-waf-cloudfront-scope.json` | WAF scope | ready |
| `Lab2/Lab2A/deliverables/proof/alb_direct_blocked.txt` | ALB direct blocked (timeout) | ready |
| `Lab2/Lab2A/deliverables/proof/dig_cf_proof.txt` | CNAME to CloudFront | ready |

---

## Proof — 2B (core)

| Filename | Purpose | Status |
|----------|---------|--------|
| `Lab2/Lab2B/deliverables/proof/proof-static-example-1.txt` | Static Hit #1 | ready |
| `Lab2/Lab2B/deliverables/proof/proof-static-example-2.txt` | Static Hit #2, Age increases | ready |
| `Lab2/Lab2B/deliverables/proof/proof-static-qs-v1.txt` | ?v=1 cache key | ready |
| `Lab2/Lab2B/deliverables/proof/proof-static-qs-v2.txt` | ?v=2 same object | ready |
| `Lab2/Lab2B/deliverables/proof/proof-api-list-1.txt` | /api/list no cache | ready |
| `Lab2/Lab2B/deliverables/proof/proof-api-list-2.txt` | /api/list no cache #2 | ready |

---

## Proof — 2B (Be A Man A)

| Filename | Purpose | Status |
|----------|---------|--------|
| `Lab2/Lab2B/deliverables/proof/proof-public-feed-miss.txt` | public-feed Miss | ready |
| `Lab2/Lab2B/deliverables/proof/proof-public-feed-hit.txt` | public-feed Hit, Age | ready |

---

## Proof — 2B (Be A Man B)

| Filename | Purpose | Status |
|----------|---------|--------|
| `Lab2/Lab2B/deliverables/proof/proof-invalidation-before.txt` | Hit before invalidation | ready |
| `Lab2/Lab2B/deliverables/proof/proof-invalidation-after.txt` | Miss after invalidation | ready |
| `Lab2/Lab2B/deliverables/proof/proof-invalidation-record.json` | Invalidation ID, /static/index.html | ready |
| `Lab2/Lab2B/deliverables/proof/proof-invalidation-example-record.json` | Invalidation /static/example.txt | ready |

---

## Proof — 2B (Be A Man C)

| Filename | Purpose | Status |
|----------|---------|--------|
| `Lab2/Lab2B/deliverables/proof/proof-manc-miss.txt` | Miss with ETag, Last-Modified | ready |
| `Lab2/Lab2B/deliverables/proof/proof-manc-hit.txt` | Hit with ETag | ready |
| `Lab2/Lab2B/deliverables/proof/proof-manc-304.txt` | 304 conditional request | ready |
| `Lab2/Lab2B/deliverables/proof/proof-manc-refreshhit.txt` | *(Shows Hit; literal RefreshHit not required for pass)* | partial |

---

## Written explanations

| Filename | Purpose | Status |
|----------|---------|--------|
| `Lab2/Lab2B/deliverables/docs/2b_cache_explanation.txt` | Cache key / forward (Core B.B) | ready |
| `Lab2/Lab2B/deliverables/docs/chewbacca_haiku.txt` | Haiku 漢字 (Core C) | ready |
| `Lab2/Lab2B/deliverables/docs/2b_honors_paragraph.txt` | Origin-driven (ManA) | ready |
| `Lab2/Lab2B/deliverables/docs/2b_manb_invalidation_policy.txt` | Invalidate vs version (ManB) | ready |
| `Lab2/Lab2B/deliverables/docs/2b_manc_refreshhit_explanation.txt` | RefreshHit (ManC) | ready |

---

## Class questions

| Filename | Purpose | Status |
|----------|---------|--------|
| `Lab2/Lab2B/deliverables/docs/2b_class_questions_answers.txt` | Failure-injection answers | optional / not required per spec |

---

## Be A Man artifacts (summary)

| Item | Location | Status |
|------|----------|--------|
| A.4 Response headers policy | lab2b_response_headers_policy.tf | ready |
| ManA Terraform + app + proof + paragraph | See Terraform, proof, 2b_honors_paragraph.txt | ready |
| ManB invalidation + before/after + paragraph | proof-invalidation-*, 2b_manb_invalidation_policy.txt | ready |
| ManC validators + 304 + paragraph | proof-manc-*, ec2.tf, 2b_manc_refreshhit_explanation.txt | ready (RefreshHit literal optional) |

---

## Gate outputs

| Filename | Purpose | Status |
|----------|---------|--------|
| `Lab2/Lab2A/deliverables/verification/gates/gate_network_db_run.txt` | Network + RDS | ready (FAIL: VPC) |
| `Lab2/Lab2A/deliverables/verification/gates/gate_secrets_run.txt` | Secrets + IAM | ready (PASS) |
| `Lab2/Lab2A/deliverables/verification/gates/gate_cf_alb_run.txt` | CF + ALB | ready (FAIL: strictness) |
| `Lab2/Lab2A/deliverables/verification/gates/gate_cache_run.txt` | Cache policy | ready (FAIL: strictness) |
| `Lab2/Lab2A/deliverables/verification/gates/GATE_SUMMARY.md` | Explanation of failures | ready |

---

## Live vs repo state

| Note | Status |
|------|--------|
| **Live domain for proof:** app.cloudyjones.xyz (spec example: chewbacca-growl.com) | — |
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
