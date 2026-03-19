# LAB2 — CloudFront, WAF, and Caching

**SEIR Foundations / AWS Cloud Engineering**

This folder contains the implementation, verification artifacts, and submission materials for Lab 2 (2A: CDN/WAF/ALB, 2B: Cache behavior and proofs).

---

## What the lab is

- **2A:** Put CloudFront in front of your ALB with a custom domain (Route 53), HTTPS (ACM), WAF, and origin cloaking. Prove traffic flows through CloudFront and direct ALB access is blocked.
- **2B:** Configure cache behaviors (static vs API), prove cache hits/misses, origin-driven caching, invalidation, and conditional requests (ETag/304).

---

## Where things live

| What | Where |
|------|--------|
| **Code (2A)** | [2a/src/](2a/) — Terraform, scripts, gate runner (Python/shell) |
| **Code (2B)** | [2b/src/](2b/) — Scripts; Terraform for 2B is in 2a (shared stack) |
| **Proof & verification (2A)** | [2a/deliverables/verification/](2a/deliverables/verification/) — curl/dig, AWS CLI, gates |
| **Proof & verification (2B)** | [2b/deliverables/verification/](2b/deliverables/verification/) — curl proofs, invalidation records |
| **Architecture / explanations** | [2a/deliverables/architecture/](2a/deliverables/architecture/), [2b/deliverables/architecture/](2b/deliverables/architecture/) |
| **Grader entry point** | [docs/GRADER_START_HERE.md](docs/GRADER_START_HERE.md) (or root [GRADER_START_HERE.md](GRADER_START_HERE.md)) |
| **Submission checklist** | [docs/FINAL_SUBMISSION_MAP.md](docs/FINAL_SUBMISSION_MAP.md) or [FINAL_SUBMISSION_MAP.md](FINAL_SUBMISSION_MAP.md) |

---

## How to run verification

1. **Gates (2A)** — From repo root:
   ```bash
   chmod +x SEIR_Foundations/LAB2/2a/src/scripts/run_all_gates_commands.sh
   ./SEIR_Foundations/LAB2/2a/src/scripts/run_all_gates_commands.sh
   ```
   Set `DB_ID` and `SECRET_ID` in the script or env if needed. Outputs go to `2a/deliverables/verification/gates/`.

2. **Terraform (2A)** — From `2a/src/terraform/`:
   ```bash
   terraform init && terraform plan
   ```

3. **Proof capture** — Use `2a/src/scripts/capture_curl_proofs.sh` and `2b/src/scripts/capture_all_proofs.sh` as reference; run against your live domain.

---

## Final deliverables (summary)

- **2A:** Terraform in `2a/src/terraform/`, proof in `2a/deliverables/verification/` (curl_checks, aws_checks, gates), architecture in `2a/deliverables/architecture/`.
- **2B:** Proof and explanations in `2b/deliverables/` (verification, architecture), submission summary in `2b/deliverables/submission_summary.md`.

For the full checklist and status of each file, see **FINAL_SUBMISSION_MAP.md** and **DELIVERABLES_INDEX.md** in this folder or in `docs/`.
