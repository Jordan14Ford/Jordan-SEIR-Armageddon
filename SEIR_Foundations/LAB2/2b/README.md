# 2B — Cache Behavior, Proofs, and Be A Man

Lab 2 Part B: Cache policies, proof of cache hits/misses, origin-driven caching, invalidation, and conditional requests (ETag/304).

---

## What was built

- **Static caching:** `/static/*` with aggressive TTL; proof of Hit, Age, cache key (e.g. query string excluded).
- **API no-cache:** `/api/*` (e.g. `/api/list`) with no-store / private; proof of `x-cache: Error` and no caching.
- **Origin-driven (Be A Man A):** `/api/public-feed` uses origin Cache-Control; proof of Miss → Hit.
- **Invalidation (Be A Man B):** Before/after invalidation proof; invalidation records.
- **Conditional requests (Be A Man C):** ETag, Last-Modified; proof of 304 and Hit.

Terraform for 2B (cache policies, response headers, origin-driven) lives in **2a** (shared CloudFront stack).

---

## Where the proof is

| Category | Path |
|----------|------|
| **Verification** | [deliverables/verification/](deliverables/verification/) — all proof-*.txt, proof-*.json |
| **Architecture / explanations** | [deliverables/architecture/](deliverables/architecture/) — cache explanation, haiku, Be A Man paragraphs |
| **Submission summary** | [deliverables/submission_summary.md](deliverables/submission_summary.md) |

---

## How to run verification

- **Proof capture:** Use `2a/src/scripts/capture_curl_proofs.sh` or the repo’s `capture_all_proofs.sh` (if present) against your live domain; save outputs into `deliverables/verification/`.
- **Terraform:** No separate 2B Terraform directory; apply from `2a/src/terraform/`.

---

## Final deliverables

- **Evidence:** `deliverables/verification/` (static, API, public-feed, invalidation, ManC).
- **Docs:** `deliverables/architecture/` (2b_cache_explanation, chewbacca_haiku, 2b_honors_paragraph, 2b_manb_invalidation_policy, 2b_manc_refreshhit_explanation).
- **Summary:** `deliverables/submission_summary.md`.
