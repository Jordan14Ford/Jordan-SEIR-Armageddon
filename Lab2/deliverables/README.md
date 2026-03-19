# Lab 2 — Deliverables (Submission Hub)

This folder is the **single entry point** for verifying and submitting Lab 2. Lab 2 is one continuous lab: 2A (CloudFront + ALB + origin cloaking) and 2B (caching correctness + Be A Man).

## Structure

| Folder | Purpose |
|--------|---------|
| **docs/** | Master index, submission map, gaps checklist, remaining work report, and **full review report** (names, setup, details, reasoning, structure). **Start here for grading.** |
| **proof/** | CLI evidence (curl, invalidation records). Canonical files live under `../Lab2A/deliverables/proof` and `../Lab2B/deliverables/proof`. See `proof/README.md`. |
| **verification/** | 2A verification outputs (CloudFront, Route53, WAF, ALB). See `verification/README.md`. |
| **gates/** | Automated gate run outputs (PASS/FAIL). See `gates/README.md`. |
| **summaries/** | Short summaries and context for graders. |

## Quick start for graders

**Start here:** **docs/GRADER_START_HERE.md** — ordered list of what to read and where proof/verification live.

Then:
1. **docs/DELIVERABLES_INDEX.md** — every deliverable, what it proves, and status.
2. **docs/FINAL_SUBMISSION_MAP.md** — submission checklist with file paths and status.
3. **docs/REMAINING_GAPS_CHECKLIST.md** — what (if anything) is still pending.
4. Proof and verification files: follow the paths in the index (under `Lab2A/deliverables/` and `Lab2B/deliverables/`).

## Repo layout (why two deliverable trees)

- **Lab2A/deliverables/** — 2A proof (CloudFront 200, DNS, WAF, ALB blocked) and verification.
- **Lab2B/deliverables/** — 2B proof (static cache, API no-cache, public-feed, invalidation, ManC) and written docs.
- **Lab2/deliverables/** (this folder) — Master docs only; points to the above for actual proof/verification files so there is one place to look and no duplicated artifacts.
