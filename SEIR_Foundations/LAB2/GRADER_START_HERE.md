# Lab 2 — Grader Start Here

Use this order to verify and grade Lab 2. All paths are relative to the **repo root** (Armageddon).  
**This copy lives under `SEIR_Foundations/LAB2/`** — paths below use that layout.

---

## 1. Read these (in order)

| Order | File | Purpose |
|-------|------|---------|
| 1 | **DELIVERABLES_INDEX.md** (this folder) | Every deliverable file, what it proves, core vs Be A Man vs optional, status (ready/partial/pending). Proof lives under `SEIR_Foundations/LAB2/2a/deliverables/verification/` and `2b/deliverables/verification/`. |
| 2 | **FINAL_SUBMISSION_MAP.md** (this folder) | Submission checklist: Terraform, proof, written docs, gates; each with filename, purpose, status |
| 3 | **REMAINING_GAPS_CHECKLIST.md** (this folder) | What is still needed: must do / should do / optional polish; no items invented |
| 4 | **LAB2_REMAINING_WORK_REPORT.md** (this folder) | Evidence-based report: definitely done, partial, missing, optional, and what is needed before done |
| 5 | **LAB2_FULL_REVIEW_REPORT.md** (this folder) | Full lab review: names, setup, details, reasoning, structure — validate the entirety of the lab here |

---

## 2. Where the actual proof and verification live

| Content | Path from repo root |
|---------|----------------------|
| **2A proof** (curl/dig, AWS) | `SEIR_Foundations/LAB2/2a/deliverables/verification/curl_checks/`, `aws_checks/` |
| **2A gate outputs** | `SEIR_Foundations/LAB2/2a/deliverables/verification/gates/` |
| **2B proof** (static, API, public-feed, invalidation, ManC) | `SEIR_Foundations/LAB2/2b/deliverables/verification/` |

Summaries: `2a/deliverables/verification/verification_summary.md`, `2b/deliverables/submission_summary.md`.

---

## 3. Terraform to submit / reference

All under **SEIR_Foundations/LAB2/2a/src/terraform/** (2A and 2B share the same CloudFront stack):

- `lab2_cloudfront_alb.tf` — CloudFront distribution, behaviors
- `lab2_cloudfront_origin_cloaking.tf` — ALB SG + listener rule (origin cloaking)
- `lab2_cloudfront_r53.tf` — Route53 A alias records
- `lab2_cloudfront_shield_waf.tf` — WAF WebACL CLOUDFRONT scope
- `lab2b_cache_policies.tf` — Cache + origin request policies (2B)
- `lab2b_response_headers_policy.tf` — Cache-Control on /static/* (Be A Man A.4)
- `lab2b_honors_origin_driven.tf` — UseOriginCacheControlHeaders for /api/public-feed (Be A Man A)

App routes (e.g. `/api/list`, `/api/public-feed`, `/static/example.txt` with ETag): **Lab1/Lab1C-V2/ec2.tf**.

---

## 4. Quick status

- **Core 2A + 2B:** Terraform and proof present; ALB direct proof shows timeout (stronger than 403); DNS/WAF/CloudFront evidenced.
- **Be A Man A/B/C:** Terraform, proof, and written paragraphs present. ManC literal RefreshHit not captured (304 + explanation used).
- **Gates:** Run; 1 PASS (secrets), 3 FAIL (documented in GATE_SUMMARY.md).

See **FINAL_SUBMISSION_MAP.md** and **REMAINING_GAPS_CHECKLIST.md** for full detail.
