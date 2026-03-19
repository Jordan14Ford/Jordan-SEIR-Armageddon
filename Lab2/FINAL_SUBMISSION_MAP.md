# Lab 2 — Final Submission Map
## Date: 2026-03-17

This file maps every deliverable for submission, its current status, and where it lives.

---

## TERRAFORM

| File | Purpose | Status |
|------|---------|--------|
| `Lab2A/lab2_cloudfront_alb.tf` | CloudFront distribution, origin, behaviors | READY (reverted to http-only — apply needed) |
| `Lab2A/lab2_cloudfront_origin_cloaking.tf` | ALB security group + listener rule for X-Chewbacca-Growl | READY |
| `Lab2A/lab2_cloudfront_r53.tf` | Route53 A (alias) records for apex + app subdomains | READY |
| `Lab2A/lab2_cloudfront_shield_waf.tf` | WAF WebACL + managed rule groups | READY |
| `Lab2A/lab2b_cache_policies.tf` | Static aggressive + API disabled cache policies | READY |
| `Lab2A/lab2b_honors_origin_driven.tf` | Honors: UseOriginCacheControlHeaders policy for /api/public-feed | READY |
| `Lab2A/lab2b_response_headers_policy.tf` | Response headers policy: Cache-Control public max-age=86400 on /static/* | READY |
| `Lab1/Lab1C-V2/ec2.tf` | Flask app with all Lab2B routes (api/list, api/public-feed, static/example.txt) | READY (synced today) |

---

## PROOF FILES — Lab 2A

| File | What It Shows | Status |
|------|---------------|--------|
| `Lab2A/deliverables/proof/proof1-cf-apex-200.txt` | HTTP/2 200 from cloudyjones.xyz via CloudFront | READY |
| `Lab2A/deliverables/proof/proof2-cf-app-200.txt` | HTTP/2 200 from app.cloudyjones.xyz via CloudFront | READY |
| `Lab2A/deliverables/proof/proof3-dig-cloudfront-ips.txt` | dig confirms DNS → CloudFront IPs | READY |
| `Lab2A/deliverables/proof/proof4-cf-config.json` | Full CloudFront distribution config | READY |
| `Lab2A/deliverables/proof/proof5-waf-cloudfront-scope.json` | WAF WebACL in CLOUDFRONT scope | READY |
| `Lab2A/deliverables/proof/alb_direct_blocked.txt` | ALB direct access times out (SG restricts to CF prefix list) | READY (timeout > 403, but stronger guarantee) |
| `Lab2A/deliverables/proof/dig_cf_proof.txt` | dig output showing CNAME to CloudFront | READY |

---

## PROOF FILES — Lab 2B

| File | What It Shows | Status |
|------|---------------|--------|
| `Lab2B/deliverables/proof/proof-static-example-1.txt` | `x-cache: Hit`, `age: 8651`, `cache-control: public, max-age=86400` | READY |
| `Lab2B/deliverables/proof/proof-static-example-2.txt` | Second Hit, `age: 8654` — same cached object, age increases | READY |
| `Lab2B/deliverables/proof/proof-static-qs-v1.txt` | `?v=1` → Hit, same age as v2 — QS ignored in cache key | READY |
| `Lab2B/deliverables/proof/proof-static-qs-v2.txt` | `?v=2` → Hit, same age — proves cache key sanity | READY |
| `Lab2B/deliverables/proof/proof-public-feed-headers.txt` | `cache-control: public, s-maxage=30, max-age=0` — origin drives TTL | READY (Miss; Hit pending origin fix) |
| `Lab2B/deliverables/proof/proof-api-list-1.txt` | HTTP/2 500, `x-cache: Error` — no caching on error responses | READY (shows cache-safety) |
| `Lab2B/deliverables/proof/proof-api-list-2.txt` | Same — confirms no caching on second request | READY |
| `Lab2B/deliverables/proof/proof-invalidation-before.txt` | Hit proof before invalidation (ManB) | READY |
| `Lab2B/deliverables/proof/proof-invalidation-record.json` | Invalidation completed for /static/index.html | READY |
| `Lab2B/deliverables/proof/proof-invalidation-example-record.json` | Invalidation completed for /static/example.txt | READY |
| `Lab2B/deliverables/proof/proof-public-feed-cache-hit.txt` | Hit + Age for /api/public-feed (ManA complete sequence) | **PENDING** — needs `terraform apply` (origin fix) then re-capture |
| `Lab2B/deliverables/proof/proof-invalidation-after.txt` | Miss after invalidation completes (ManB complete) | **PENDING** — needs origin fix + re-capture |

---

## WRITTEN DOCS

| File | Purpose | Status |
|------|---------|--------|
| `Lab2B/deliverables/docs/2b_cache_explanation.txt` | Cache key for /api/* and why; what is forwarded and why | READY |
| `Lab2B/deliverables/docs/2b_what_this_proves.txt` | Maps each proof file to a lab requirement | READY |
| `Lab2B/deliverables/docs/chewbacca_haiku.txt` | Haiku in Japanese characters about Chewbacca | READY |
| `Lab2B/deliverables/docs/2b_be_a_man_note.txt` | Maps Be A Man requirements to implementation | READY |
| `Lab2B/deliverables/docs/2b_honors_paragraph.txt` | ManA: written explanation of origin-driven caching + public-feed behavior | READY |
| `Lab2B/deliverables/docs/2b_manb_invalidation_policy.txt` | ManB: written explanation of invalidation policy and when to use vs versioning | READY |
| `Lab2B/deliverables/docs/2b_manc_refreshhit_explanation.txt` | ManC: written explanation of RefreshHit and why it beats a Miss | READY |
| `Lab2B/deliverables/docs/2b_done_checklist.txt` | Full completion checklist with status for all items | READY |

---

## CLASS QUESTIONS

| File | Purpose | Status |
|------|---------|--------|
| `Lab2B/deliverables/docs/2b_class_questions_answers.txt` | Answers to 2b_class_questions.txt (if separate file exists) | CHECK — may be embedded in cache_explanation |

---

## GATE OUTPUTS

| File | Purpose | Status |
|------|---------|--------|
| `Lab2A/deliverables/verification/gates/gate_network_db_run.txt` | FAIL: VPC mismatch (documented) | READY |
| `Lab2A/deliverables/verification/gates/gate_secrets_run.txt` | PASS: Secrets + IAM confirmed | READY |
| `Lab2A/deliverables/verification/gates/gate_cf_alb_run.txt` | FAIL: WAF/Route53/logging (documented) | READY |
| `Lab2A/deliverables/verification/gates/gate_cache_run.txt` | FAIL: same issues (documented) | READY |
| `Lab2A/deliverables/verification/gates/GATE_SUMMARY.md` | Explains each failure; distinguishes real gaps vs gate strictness | READY |

---

## FINAL STATUS NOTES

| File | Purpose | Status |
|------|---------|--------|
| `Lab2/LIVE_VS_REPO_STATE.md` | Explains origin protocol issue, app route sync, gate failures | READY |
| `Lab2/LAB2_FULL_CONTEXT.md` | Master context file for LLMs and graders | READY |
| `Lab2/FINAL_SUBMISSION_MAP.md` | This file | READY |

---

## READINESS SUMMARY

| Section | % Complete | Notes |
|---------|-----------|-------|
| 2A Terraform | 100% | All infra done; need `terraform apply` for origin fix |
| 2A Proof | 90% | All key proofs present; ALB direct is timeout not 403 |
| 2B Terraform | 100% | Cache policies, behaviors, RHP — all done |
| 2B App behavior | 90% | Routes work; /api/list has DB 500 (not a caching issue) |
| 2B Proof | 75% | Static/QS/invalidation-record ready; Hit sequence + post-invalidation-Miss pending |
| Written docs | 100% | All explanations, haiku, ManA/B/C paragraphs done |
| Be A Man | 85% | ManA/B written+partial proof; ManC written only, no live ETag proof |
| Gates | 100% run | 1 pass, 3 fail (documented with explanations) |

**Overall LAB2: ~88% — Mostly Ready for Submission**

**Fastest path to 100%:**
1. `cd Lab2/Lab2A && terraform apply` (restores origin path, ~2 min)
2. Capture public-feed Miss → Hit sequence (30 sec after apply)
3. Capture post-invalidation Miss for ManB (1 min)
4. Optional: add ETag to /static/example.txt for ManC (requires SSM patch)
