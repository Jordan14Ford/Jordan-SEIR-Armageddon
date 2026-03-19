# 2B Submission Summary

Checklist and status for Lab 2B deliverables (cache behavior, proofs, Be A Man).

---

## Core 2B

| Item | Location | Status |
|------|----------|--------|
| Static cache proof (Hit, Age) | deliverables/verification/proof-static-example-1.txt, proof-static-example-2.txt | ready |
| Cache key (query string) | proof-static-qs-v1.txt, proof-static-qs-v2.txt | ready |
| API no-cache | proof-api-list-1.txt, proof-api-list-2.txt | ready |
| Cache explanation | deliverables/architecture/2b_cache_explanation.txt | ready |
| Haiku (Core C) | deliverables/architecture/chewbacca_haiku.txt | ready |

---

## Be A Man A (origin-driven)

| Item | Location | Status |
|------|----------|--------|
| Terraform | 2a/src/terraform/ (UseOriginCacheControlHeaders for /api/public-feed) | ready |
| Proof (Miss, Hit) | proof-public-feed-miss.txt, proof-public-feed-hit.txt | ready |
| Paragraph | deliverables/architecture/2b_honors_paragraph.txt | ready |

---

## Be A Man B (invalidation)

| Item | Location | Status |
|------|----------|--------|
| Before/after proof | proof-invalidation-before.txt, proof-invalidation-after.txt | ready |
| Invalidation records | proof-invalidation-record.json, proof-invalidation-example-record.json | ready |
| Paragraph | deliverables/architecture/2b_manb_invalidation_policy.txt | ready |

---

## Be A Man C (ETag / 304)

| Item | Location | Status |
|------|----------|--------|
| Proof (Miss, Hit, 304) | proof-manc-miss.txt, proof-manc-hit.txt, proof-manc-304.txt | ready |
| RefreshHit | proof-manc-refreshhit.txt (content may show Hit; literal RefreshHit optional per spec) | partial / ready |
| Paragraph | deliverables/architecture/2b_manc_refreshhit_explanation.txt | ready |

---

## Optional

- **2b_class_questions_answers.txt** — Only if required by instructor.
- **Literal x-cache: RefreshHit** — Optional; 304 + paragraph suffice per spec.

---

For full lab-wide checklist and grader entry, see **LAB2/README.md** and **LAB2/docs/GRADER_START_HERE.md** (or root GRADER_START_HERE.md).
