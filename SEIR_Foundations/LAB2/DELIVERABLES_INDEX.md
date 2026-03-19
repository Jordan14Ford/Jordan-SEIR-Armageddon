# Lab 2 — Deliverables Index

Every deliverable file, what it proves, category (core / Be A Man / optional), and status.

**This copy is under `SEIR_Foundations/LAB2/`.** For the new layout: **2A** → `2a/deliverables/verification/` (curl_checks, aws_checks, gates) and `2a/src/terraform/`; **2B** → `2b/deliverables/verification/` and `2b/deliverables/architecture/`. See **FINAL_SUBMISSION_MAP.md** for the full path checklist in this layout.

---

## Terraform (submit / reference)

| File | Purpose | Category | Status |
|------|---------|----------|--------|
| `Lab2/Lab2A/lab2_cloudfront_alb.tf` | CloudFront distribution, origins, behaviors (/api/public-feed, /api/*, /static/*, default) | Core 2A + 2B | READY |
| `Lab2/Lab2A/lab2_cloudfront_origin_cloaking.tf` | ALB SG (CloudFront prefix list), listener rule (custom header) | Core 2A | READY |
| `Lab2/Lab2A/lab2_cloudfront_r53.tf` | Route53 A (alias) apex + app → CloudFront | Core 2A | READY |
| `Lab2/Lab2A/lab2_cloudfront_shield_waf.tf` | WAF WebACL CLOUDFRONT scope | Core 2A | READY |
| `Lab2/Lab2A/lab2b_cache_policies.tf` | Static + API cache policies; static + API origin request policies | Core 2B (A.1, A.2) | READY |
| `Lab2/Lab2A/lab2b_response_headers_policy.tf` | Cache-Control: public, max-age=86400 on /static/* | Be A Man A.4 | READY |
| `Lab2/Lab2A/lab2b_honors_origin_driven.tf` | UseOriginCacheControlHeaders for /api/public-feed | Be A Man A | READY |
| `Lab1/Lab1C-V2/ec2.tf` | Flask app: /api/list, /api/public-feed, /static/example.txt (with ETag, Last-Modified) | Core 2B + ManA + ManC | READY |

---

## Proof files (2A)

| File | What it proves | Category | Status |
|------|----------------|----------|--------|
| `Lab2/Lab2A/deliverables/proof/proof1-cf-apex-200.txt` | HTTP 200 apex via CloudFront | Core 2A | READY |
| `Lab2/Lab2A/deliverables/proof/proof2-cf-app-200.txt` | HTTP 200 app subdomain via CloudFront | Core 2A | READY |
| `Lab2/Lab2A/deliverables/proof/proof3-dig-cloudfront-ips.txt` | DNS → CloudFront IPs | Core 2A | READY |
| `Lab2/Lab2A/deliverables/proof/proof4-cf-config.json` | CloudFront distribution config | Core 2A | READY |
| `Lab2/Lab2A/deliverables/proof/proof5-waf-cloudfront-scope.json` | WAF in CLOUDFRONT scope | Core 2A | READY |
| `Lab2/Lab2A/deliverables/proof/alb_direct_blocked.txt` | Direct ALB access fails (timeout; SG) | Core 2A | READY (timeout, not 403) |
| `Lab2/Lab2A/deliverables/proof/dig_cf_proof.txt` | CNAME/alias to CloudFront | Core 2A | READY |

---

## Proof files (2B — core)

| File | What it proves | Category | Status |
|------|----------------|----------|--------|
| `Lab2/Lab2B/deliverables/proof/proof-static-example-1.txt` | /static/example.txt — Hit, Age, Cache-Control | Core B.A, D.1 | READY |
| `Lab2/Lab2B/deliverables/proof/proof-static-example-2.txt` | Second request — same cache, Age increases | Core B.A, D.1 | READY |
| `Lab2/Lab2B/deliverables/proof/proof-static-qs-v1.txt` | ?v=1 — cache key ignores QS | Core D.3 | READY |
| `Lab2/Lab2B/deliverables/proof/proof-static-qs-v2.txt` | ?v=2 — same cached object | Core D.3 | READY |
| `Lab2/Lab2B/deliverables/proof/proof-api-list-1.txt` | /api/list — x-cache: Error, private no-store | Core B.A, D.2 | READY |
| `Lab2/Lab2B/deliverables/proof/proof-api-list-2.txt` | Second /api/list — no caching | Core D.2 | READY |

---

## Proof files (2B — Be A Man A)

| File | What it proves | Category | Status |
|------|----------------|----------|--------|
| `Lab2/Lab2B/deliverables/proof/proof-public-feed-miss.txt` | /api/public-feed — Miss, origin Cache-Control | Be A Man A | READY |
| `Lab2/Lab2B/deliverables/proof/proof-public-feed-hit.txt` | /api/public-feed — Hit, Age (within TTL) | Be A Man A | READY |
| `Lab2/Lab2B/deliverables/proof/proof-public-feed-headers.txt` | Same endpoint, headers only (if present) | Be A Man A | READY (redundant with miss/hit) |

---

## Proof files (2B — Be A Man B)

| File | What it proves | Category | Status |
|------|----------------|----------|--------|
| `Lab2/Lab2B/deliverables/proof/proof-invalidation-before.txt` | Static Hit before invalidation | Be A Man B | READY |
| `Lab2/Lab2B/deliverables/proof/proof-invalidation-after.txt` | Static Miss after invalidation | Be A Man B | READY |
| `Lab2/Lab2B/deliverables/proof/proof-invalidation-record.json` | create-invalidation completed (/static/index.html) | Be A Man B | READY |
| `Lab2/Lab2B/deliverables/proof/proof-invalidation-example-record.json` | Invalidation for /static/example.txt | Be A Man B | READY |

---

## Proof files (2B — Be A Man C)

| File | What it proves | Category | Status |
|------|----------------|----------|--------|
| `Lab2/Lab2B/deliverables/proof/proof-manc-miss.txt` | /static/example.txt — Miss with ETag, Last-Modified | Be A Man C | READY |
| `Lab2/Lab2B/deliverables/proof/proof-manc-hit.txt` | Hit with ETag in response | Be A Man C | READY |
| `Lab2/Lab2B/deliverables/proof/proof-manc-304.txt` | 304 Not Modified — conditional request | Be A Man C | READY |
| `Lab2/Lab2B/deliverables/proof/proof-manc-refreshhit.txt` | *(Content shows Hit; not literal RefreshHit)* | Be A Man C | PARTIAL (name vs content) |
| `Lab2/Lab2B/deliverables/proof/proof-manc-prime.txt` | Optional / duplicate capture | Optional | READY (if present) |

---

## Written explanations (core)

| File | Purpose | Category | Status |
|------|----------|----------|--------|
| `Lab2/Lab2B/deliverables/docs/2b_cache_explanation.txt` | Cache key for /api/*; what is forwarded and why | Core B.B | READY |
| `Lab2/Lab2B/deliverables/docs/chewbacca_haiku.txt` | Haiku 漢字 re Chewbacca | Core C | READY |

---

## Written explanations (Be A Man)

| File | Purpose | Category | Status |
|------|----------|----------|--------|
| `Lab2/Lab2B/deliverables/docs/2b_honors_paragraph.txt` | Why origin-driven caching; when to disable | Be A Man A | READY |
| `Lab2/Lab2B/deliverables/docs/2b_manb_invalidation_policy.txt` | When invalidate vs version; why /* restricted | Be A Man B | READY |
| `Lab2/Lab2B/deliverables/docs/2b_manc_refreshhit_explanation.txt` | What RefreshHit means; why better than Miss | Be A Man C | READY |

---

## Supporting docs (reference only)

| File | Purpose | Category | Status |
|------|----------|----------|--------|
| `Lab2/Lab2B/deliverables/docs/2b_what_this_proves.txt` | Maps proof files to requirements | Reference | READY |
| `Lab2/Lab2B/deliverables/docs/2b_be_a_man_note.txt` | Be A Man requirement mapping | Reference | READY (may be stale; checklist is source) |
| `Lab2/Lab2B/deliverables/docs/2b_done_checklist.txt` | Detailed completion checklist | Reference | READY |
| `Lab2/Lab2A/deliverables/docs/2a_*` | 2A doc set | Reference | READY |

---

## Class questions

| File | Purpose | Category | Status |
|------|----------|----------|--------|
| `Lab2/Lab2B/deliverables/docs/2b_class_questions_answers.txt` | Answers to 2b_class_questions.txt | Optional | NOT PRESENT (spec: no pre-written answers required) |

---

## Gate outputs

| File | Purpose | Category | Status |
|------|----------|----------|--------|
| `Lab2/Lab2A/deliverables/verification/gates/gate_network_db_run.txt` | Network + RDS gate output | Verification | READY (FAIL: VPC mismatch) |
| `Lab2/Lab2A/deliverables/verification/gates/gate_secrets_run.txt` | Secrets + IAM gate output | Verification | READY (PASS) |
| `Lab2/Lab2A/deliverables/verification/gates/gate_cf_alb_run.txt` | CloudFront + ALB gate output | Verification | READY (FAIL: strictness) |
| `Lab2/Lab2A/deliverables/verification/gates/gate_cache_run.txt` | Cache policy gate output | Verification | READY (FAIL: strictness) |
| `Lab2/Lab2A/deliverables/verification/gates/GATE_SUMMARY.md` | Explanation of each gate result | Verification | READY |

---

## Live vs repo state

| File | Purpose | Status |
|------|----------|--------|
| `Lab2/LIVE_VS_REPO_STATE.md` | Origin protocol, app sync, gate failures | READY (if present) |
| `Lab2/LAB2_FULL_CONTEXT.md` | Master context for graders | READY (if present) |

---

**Legend:** READY = file exists and supports the deliverable. PARTIAL = file exists but does not fully match requirement (e.g. RefreshHit filename vs Hit content). PENDING = not yet done. NOT PRESENT = no file; optional or not required per spec.
