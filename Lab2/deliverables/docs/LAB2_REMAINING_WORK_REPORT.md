# Lab 2 — Remaining Work Report (Evidence-Based)

**Last verified:** 2026-03-18 (repo files and proof contents inspected).  
Generated from actual repo and proof inspection. No assumptions; gaps are only closed when a real file or proof shows it.

**Live domain for proof capture:** `app.cloudyjones.xyz` (spec examples use `chewbacca-growl.com`).

---

## A. What is definitely done

### Core Lab 2 (2b_deliverables.txt)

| Requirement | Evidence |
|-------------|----------|
| **Deliverable A.1** — Two cache policies (static aggressive, API disabled/origin-driven) | `Lab2A/lab2b_cache_policies.tf`: `cloudyjones_static_cp`, `cloudyjones_api_cp`; `lab2b_honors_origin_driven.tf` for UseOriginCacheControlHeaders |
| **Deliverable A.2** — Two origin request policies (static minimal, API forwards headers/QS) | `Lab2A/lab2b_cache_policies.tf`: `cloudyjones_static_orp`, `cloudyjones_api_orp` |
| **Deliverable A.3** — Two cache behaviors (/static/*, /api/*) | `Lab2A/lab2_cloudfront_alb.tf`: path_patterns and policy attachments |
| **Deliverable A.4** — Be A Man: response headers policy (Cache-Control on static) | `Lab2A/lab2b_response_headers_policy.tf`: Cache-Control public, max-age=86400; attached to /static/* |
| **Deliverable B.A** — curl /static/example.txt showing cache hit | `Lab2B/deliverables/proof/proof-static-example-1.txt`, `proof-static-example-2.txt`: x-cache: Hit, age present, cache-control: public, max-age=86400 |
| **Deliverable B.A** — curl /api/list showing must NOT cache | `Lab2B/deliverables/proof/proof-api-list-1.txt`, `proof-api-list-2.txt`: x-cache: Error, cache-control: private, no-store |
| **Deliverable B.B** — Written explanation (cache key for /api/*, what is forwarded and why) | `Lab2B/deliverables/docs/2b_cache_explanation.txt` |
| **Deliverable C** — Haiku 漢字 re Chewbacca | `Lab2B/deliverables/docs/chewbacca_haiku.txt` (ちゅーバッカの 完璧な力と 心の唸り) |
| **Deliverable D.1** — Static caching proof (twice, Age increases) | proof-static-example-1/2 show Hit, age |
| **Deliverable D.2** — API must NOT cache (Age absent, fresh behavior) | proof-api-list-1/2: no Age, x-cache: Error |
| **Deliverable D.3** — Query string sanity (?v=1, ?v=2 same object) | `proof-static-qs-v1.txt`, `proof-static-qs-v2.txt` show Hit, same cache object |

### Be A Man (umbrella + A.4)

| Requirement | Evidence |
|-------------|----------|
| Safe caching for public GET using Cache-Control from origin | RHP on /static/*; origin-driven for /api/public-feed |
| Demonstrate correct behavior with headers and evidence | Static and public-feed proofs above |
| Response headers policy (A.4) | lab2b_response_headers_policy.tf |

### Be A Man A (Honors — origin-driven caching)

| Requirement | Evidence |
|-------------|----------|
| /api/public-feed returns Cache-Control: public, s-maxage=30, max-age=0 | proof-public-feed-miss.txt, proof-public-feed-hit.txt; ec2.tf route |
| /api/list returns Cache-Control: private, no-store | proof-api-list-1.txt; ec2.tf route |
| Terraform UseOriginCacheControlHeaders for /api/public-feed | lab2b_honors_origin_driven.tf; lab2_cloudfront_alb.tf behavior |
| Proof: Miss then Hit for public-feed | proof-public-feed-miss.txt (Miss), proof-public-feed-hit.txt (Hit, age: 5) |
| Proof: /api/list no Hit, private no-store | proof-api-list-1/2: x-cache: Error, cache-control: private, no-store |
| One paragraph (origin-driven vs disable) | Lab2B/deliverables/docs/2b_honors_paragraph.txt |

### Be A Man B (Honors+ — invalidation)

| Requirement | Evidence |
|-------------|----------|
| create-invalidation run (single path) | proof-invalidation-record.json: /static/index.html, Status Completed |
| Before invalidation: object cached (Hit, Age) | proof-invalidation-before.txt: x-cache: Hit, age: 18 |
| After invalidation: cache refresh (Miss or RefreshHit) | proof-invalidation-after.txt: x-cache: Miss from cloudfront |
| 1-paragraph policy (when invalidate, when version, why /* restricted) | Lab2B/deliverables/docs/2b_manb_invalidation_policy.txt |

### Be A Man C (Honors++ — validators, RefreshHit)

| Requirement | Evidence |
|-------------|----------|
| Endpoint sends validators (ETag or Last-Modified) | ec2.tf: /static/example.txt sets ETag and Last-Modified; proof-manc-miss.txt shows both headers |
| Evidence of validators in responses | proof-manc-miss.txt, proof-manc-hit.txt, proof-manc-304.txt |
| Conditional request (304) proof | proof-manc-304.txt: HTTP/2 304, etag present, x-cache: Hit |
| One-paragraph: what RefreshHit means, why better than Miss | Lab2B/deliverables/docs/2b_manc_refreshhit_explanation.txt |

### Lab 2A (infrastructure)

| Requirement | Evidence |
|-------------|----------|
| CloudFront, ALB, origin cloaking, WAF, Route53 | Terraform in Lab2A/*.tf |
| Proof: 200 via CloudFront (apex + app) | proof1-cf-apex-200.txt, proof2-cf-app-200.txt |
| Proof: ALB direct blocked | alb_direct_blocked.txt (timeout; SG restricts to CF prefix list) |
| Proof: DNS → CloudFront, WAF CLOUDFRONT scope | proof3-dig-cloudfront-ips.txt, proof5-waf-cloudfront-scope.json |

---

## B. What is partial

| Item | Evidence | Gap |
|------|----------|-----|
| **ManC: “Observe RefreshHit after TTL expiry”** | proof-manc-refreshhit.txt exists but contains **x-cache: Hit**, not “RefreshHit from cloudfront”. Validators + 304 are proven; written explanation is complete. | Lab expects x-cache: RefreshHit after TTL; that requires short max-age (e.g. 30s) and a request after TTL. Current static RHP is max-age=86400 so RefreshHit is rare. Acceptable: 304 + written explanation show understanding. |
| **Deliverable D.4 — Stale read after write** | Not run. /api/list returns 500 (DB unreachable) so POST-then-GET flow is blocked. | Optional if API has no writes; if graded, blocked by VPC/DB until fixed. |
| **2A ALB direct: 403** | alb_direct_blocked.txt shows **timeout** (no TCP), not 403. Lab text says “Expected: 403”. | Stronger than 403 (SG blocks at network layer). Some rubrics may expect 403; doc explains. |

---

## C. What is still missing

| Item | Notes |
|------|--------|
| **ManA: “After 35 seconds, MISS again”** | No third proof file showing Miss after 35s sleep. ManA checklist says “Miss → Hit → Miss”. We have Miss + Hit. Optional for full “sweat” proof; origin-driven and Hit are proven. |
| **Literal x-cache: RefreshHit from cloudfront** | No file shows that exact header. ManC pass uses validators + 304 + written explanation. |
| **2b_class_questions answers** | No separate answers file. SEIR 2b_class_questions.txt says these are instructor failure-injection scenarios; “No pre-written answers are required.” |
| **Gate passes (all green)** | 1 pass (secrets), 3 fail (network_db, cf_alb, cache). See GATE_SUMMARY.md. |

---

## D. What is only optional / polish

- **ManA third curl (Miss after 35s)** — Proves TTL expiry; Miss + Hit already show origin-driven caching.
- **ManC literal RefreshHit capture** — Short TTL + wait; 304 + paragraph already demonstrate understanding.
- **D.4 Stale read after write** — Only if API supports writes and is reachable (/api/list 500).
- **All gates PASS** — Requires VPC/DB fix, Route53/WAF/logging adjustments, possibly Linux for gate scripts.
- **Terraform invalidation action (ManB Part C Option 2)** — Optional; runbook invalidation is sufficient.

---

## E. What is still needed before LAB2 can be honestly marked done

**Must do (if you want “100%” on paper):**

1. **Nothing strictly required for core 2B + Be A Man A/B/C** — All required Terraform, app code, proofs, and written docs are present and evidence-based. /api/list 500 is an infrastructure (VPC/DB) issue, not a missing deliverable; cache-safety is proven. **If your instructor requires all gates PASS or literal `x-cache: RefreshHit from cloudfront` evidence, treat those as must-do and complete them before marking done.**

**Should do (recommended):**

2. **Update any stale references** — e.g. FINAL_SUBMISSION_MAP previously listed proof-public-feed-cache-hit and proof-invalidation-after as PENDING; both exist and are complete. Use deliverables/docs/FINAL_SUBMISSION_MAP.md as source of truth.
3. **Optional: one more ManA proof** — Third curl after `sleep 35` to /api/public-feed showing Miss (for full Miss → Hit → Miss).
4. **Optional: ManC RefreshHit** — Temporarily set short max-age on /static/example.txt (or another path), wait TTL, curl and save response showing x-cache: RefreshHit (only if grader expects it).

**Optional polish:**

5. Fix gate failures if the rubric requires gates (VPC peering or RDS in Lab2 VPC; Route53/WAF/logging to match gate expectations).
6. Add 2b_class_questions_answers.txt only if your instructor asks for it (spec says not required).

**Repo vs live:** App routes and ETag are in repo (Lab1/Lab1C-V2/ec2.tf). Live instance was patched via SSM; new instances get same code from user_data. No deliverable is blocked by “repo only” — proofs were captured from live.

---

## Summary table

| Category | Count |
|----------|--------|
| Definitely done | All core 2A/2B, Be A Man A.4, ManA, ManB, ManC (validators + 304 + paragraph) |
| Partial | ManC RefreshHit literal; D.4 (blocked); ALB direct = timeout not 403 |
| Still missing | ManA third proof (Miss after 35s); optional class_questions answers |
| Optional only | RefreshHit capture; gate fixes; Terraform invalidation action |
| **Honestly mark done?** | **Yes** — required deliverables and Be A Man items are present and evidenced. Optional items are clearly listed above. |
