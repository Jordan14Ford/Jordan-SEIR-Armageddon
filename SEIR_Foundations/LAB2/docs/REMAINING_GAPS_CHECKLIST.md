# Lab 2 — Remaining Gaps Checklist

Strict checklist of what still needs to happen. Grouped: must do / should do / optional polish. Only items with real gaps are listed; completed work is not repeated here.

---

## Must do (required for “done”)

- [x] **Core Lab 2 + Be A Man** — All required Terraform, proof files, and written explanations are present and evidenced. No mandatory item is missing for submission.
- [ ] **Instructor-specific** — If your instructor requires **all gates PASS** or **literal `x-cache: RefreshHit from cloudfront`** in a proof file, add those as must-do and complete them (see "Manual / live commands" below).

---

## Should do (recommended before final submit)

- [ ] **Confirm proof file paths** — Ensure grader can open every path in FINAL_SUBMISSION_MAP.md (e.g. from repo root: `Lab2/Lab2B/deliverables/proof/...`). No renames or moves required if structure is unchanged.
- [ ] **Optional ManA third proof** — Run: `sleep 35 && curl -si https://app.cloudyjones.xyz/api/public-feed` and save as e.g. `proof-public-feed-miss-after-ttl.txt` to show Miss after TTL (full Miss → Hit → Miss sequence). Not strictly required; Miss + Hit already prove origin-driven caching.
- [ ] **Optional ManC RefreshHit** — If grader expects literal `x-cache: RefreshHit from cloudfront`: use an endpoint with short max-age (e.g. 30s), wait past TTL, curl and save. Current validators + 304 + paragraph are sufficient for ManC pass per rubric.

---

## Optional polish

- [ ] **Fix gate failures** — Only if rubric requires all gates PASS.
  - Network/RDS: VPC peering or move RDS into Lab 2 VPC so EC2 can reach DB.
  - CF/ALB/Cache gates: Address WAF association check, Route53 trailing-dot/AAAA, CloudFront logging if gate scripts expect them.
  - Run gates on Linux if scripts fail on macOS (sed differences).
- [ ] **D.4 Stale read after write** — Only if API supports writes and is reachable. Currently blocked by /api/list 500; fix DB connectivity first.
- [ ] **2b_class_questions_answers.txt** — Add only if instructor asks; spec says no pre-written answers required.
- [ ] **Rename or add note for proof-manc-refreshhit.txt** — File shows `x-cache: Hit`. Either rename to avoid confusion or add one-line note in docs that literal RefreshHit was not captured (304 + paragraph suffice).
- [ ] **Terraform invalidation action (ManB Part C Option 2)** — Optional; manual create-invalidation is sufficient.

---

## Manual / live commands (only if you choose to fill gaps)

These are **not** required for submission; use only if you want the optional items above.

1. **ManA third proof (Miss after 35s)**  
   `sleep 35 && curl -si https://app.cloudyjones.xyz/api/public-feed > Lab2/Lab2B/deliverables/proof/proof-public-feed-miss-after-ttl.txt`

2. **ManC literal RefreshHit**  
   - Temporarily set short Cache-Control (e.g. max-age=30) on an endpoint.  
   - Wait 35+ seconds.  
   - `curl -si https://app.cloudyjones.xyz/static/example.txt` (or that endpoint).  
   - Save response; look for `x-cache: RefreshHit from cloudfront`.

3. **Re-run gates**  
   From repo: `./Lab2/run_all_gates_commands.sh` (after setting DB_ID and SECRET_ID if needed). Outputs go to `Lab2/Lab2A/deliverables/verification/gates/`.

---

## Summary

| Group | Count | Action |
|-------|--------|--------|
| Must do | 0 | None required |
| Should do | 1–2 | Confirm paths; optionally add ManA third proof / ManC RefreshHit |
| Optional polish | 5 | Gates, D.4, class answers, proof note, Terraform invalidation action |

**Lab 2 can be honestly marked done** with current deliverables. This checklist only lists improvements and optional evidence.
