# Lab 2 Reorganization Map

This document records the **before** (original `Lab2/`) and **after** (`SEIR_Foundations/LAB2/`) structure and lists exactly which files were **copied** (not deleted) into the new layout. The original `Lab2/` folder is unchanged.

---

## 1. Before (original) folder structure

```
Lab2/
├── FINAL_SUBMISSION_MAP.md
├── LAB2_FULL_CONTEXT.md
├── run_all_gates_commands.sh
├── capture_all_proofs.sh
├── patch_api_list_live.sh
├── deliverables/
│   ├── docs/          (GRADER_START_HERE, FINAL_SUBMISSION_MAP, DELIVERABLES_INDEX, etc.)
│   ├── gates/README.md
│   ├── proof/README.md
│   ├── summaries/README.md
│   └── verification/README.md
├── Lab2A/
│   ├── *.tf           (terraform at root)
│   ├── providers.tf, variables.tf, outputs.tf, data.tf
│   ├── scripts/       (verify_lab2a.sh, capture_curl_proofs.sh)
│   ├── evidence/      (proof1–proof5 duplicates)
│   ├── deliverables/
│   │   ├── proof/     (proof1–5, alb_direct_blocked, dig_cf_proof)
│   │   ├── verification/ (gates/, *.txt AWS/curl outputs)
│   │   └── docs/      (2a_*.txt)
│   └── Lab2A_Verification_and_Submission_Readiness_Report.md
├── Lab2B/
│   ├── README.md
│   └── deliverables/
│       ├── proof/     (proof-static-*, proof-api-*, proof-public-feed-*, proof-invalidation-*, proof-manc-*)
│       └── docs/      (2b_*.txt, chewbacca_haiku.txt)
└── SEIR files/LAB2/
    ├── terraform/     (reference .tf)
    ├── python/        (gate *.sh, *.py, how_to_run*.txt)
    └── 2a_readme.md, 2b_readme.md, 2a_lab.txt, 2b_*.txt
```

---

## 2. After (new) folder structure

```
SEIR_Foundations/LAB2/
├── README.md
├── GRADER_START_HERE.md
├── FINAL_SUBMISSION_MAP.md
├── DELIVERABLES_INDEX.md
├── REMAINING_GAPS_CHECKLIST.md
├── LAB2_REMAINING_WORK_REPORT.md
├── LAB2_FULL_REVIEW_REPORT.md
├── LAB2_FULL_CONTEXT.md
├── REORGANIZATION_MAP.md          (this file)
├── docs/                          (duplicate of grader docs)
├── 2a/
│   ├── README.md
│   ├── src/
│   │   ├── terraform/             (*.tf)
│   │   ├── scripts/               (verify_lab2a, capture_curl_proofs, run_all_gates_commands)
│   │   └── python/                (SEIR gate scripts, malgus, how_to_run)
│   ├── deliverables/
│   │   ├── architecture/          (Lab2A_Verification_..., architecture_summary.md)
│   │   ├── verification/
│   │   │   ├── cli/               (README only; optional CLI proof)
│   │   │   ├── curl_checks/      (proof1–3, alb_direct_blocked, dig_cf_proof)
│   │   │   ├── aws_checks/       (proof4–5, cloudfront_*, route53, waf, alb_*, etc.)
│   │   │   ├── gates/            (gate_*_result.json, gate_*_run.txt, GATE_SUMMARY.md)
│   │   │   └── verification_summary.md
│   │   ├── screenshots/           (README placeholder)
│   │   └── architecture_summary.md
│   └── notes/                      (2a_*.txt)
├── 2b/
│   ├── README.md
│   ├── src/
│   │   ├── terraform/             (empty; stack in 2a)
│   │   ├── scripts/               (capture_all_proofs.sh)
│   │   └── python/                (empty)
│   ├── deliverables/
│   │   ├── architecture/          (2b_*.txt, chewbacca_haiku.txt)
│   │   ├── verification/          (all proof-*.txt, proof-*.json)
│   │   ├── screenshots/           (README placeholder)
│   │   └── submission_summary.md
│   └── notes/                     (PROOF_NOTES.md)
└── shared/
    ├── helpers/README.md
    └── templates/README.md
```

---

## 3. Files copied (source → destination)

### 2a — Implementation

| Source | Destination |
|--------|-------------|
| `Lab2/Lab2A/lab2_cloudfront_alb.tf` | `2a/src/terraform/` |
| `Lab2/Lab2A/lab2_cloudfront_origin_cloaking.tf` | `2a/src/terraform/` |
| `Lab2/Lab2A/lab2_cloudfront_r53.tf` | `2a/src/terraform/` |
| `Lab2/Lab2A/lab2_cloudfront_shield_waf.tf` | `2a/src/terraform/` |
| `Lab2/Lab2A/lab2_ec2_s3_access.tf` | `2a/src/terraform/` |
| `Lab2/Lab2A/lab2b_cache_policies.tf` | `2a/src/terraform/` |
| `Lab2/Lab2A/lab2b_honors_origin_driven.tf` | `2a/src/terraform/` |
| `Lab2/Lab2A/lab2b_response_headers_policy.tf` | `2a/src/terraform/` |
| `Lab2/Lab2A/providers.tf` | `2a/src/terraform/` |
| `Lab2/Lab2A/variables.tf` | `2a/src/terraform/` |
| `Lab2/Lab2A/outputs.tf` | `2a/src/terraform/` |
| `Lab2/Lab2A/data.tf` | `2a/src/terraform/` |
| `Lab2/Lab2A/scripts/verify_lab2a.sh` | `2a/src/scripts/` |
| `Lab2/Lab2A/scripts/capture_curl_proofs.sh` | `2a/src/scripts/` |
| `Lab2/run_all_gates_commands.sh` | `2a/src/scripts/` (path vars updated) |
| `Lab2/SEIR files/LAB2/python/*` (all .py, .sh, .txt) | `2a/src/python/` |

### 2a — Deliverables

| Source | Destination |
|--------|-------------|
| `Lab2/Lab2A/deliverables/proof/proof1-cf-apex-200.txt` | `2a/deliverables/verification/curl_checks/` |
| `Lab2/Lab2A/deliverables/proof/proof2-cf-app-200.txt` | `2a/deliverables/verification/curl_checks/` |
| `Lab2/Lab2A/deliverables/proof/proof3-dig-cloudfront-ips.txt` | `2a/deliverables/verification/curl_checks/` |
| `Lab2/Lab2A/deliverables/proof/alb_direct_blocked.txt` | `2a/deliverables/verification/curl_checks/` |
| `Lab2/Lab2A/deliverables/proof/dig_cf_proof.txt` | `2a/deliverables/verification/curl_checks/` |
| `Lab2/Lab2A/deliverables/proof/proof4-cf-config.json` | `2a/deliverables/verification/aws_checks/` |
| `Lab2/Lab2A/deliverables/proof/proof5-waf-cloudfront-scope.json` | `2a/deliverables/verification/aws_checks/` |
| `Lab2/Lab2A/deliverables/verification/cloudfront_*.txt` | `2a/deliverables/verification/aws_checks/` |
| `Lab2/Lab2A/deliverables/verification/route53_zones.txt` | `2a/deliverables/verification/aws_checks/` |
| `Lab2/Lab2A/deliverables/verification/waf_for_distribution.txt` | `2a/deliverables/verification/aws_checks/` |
| `Lab2/Lab2A/deliverables/verification/verification_results.txt` | `2a/deliverables/verification/aws_checks/` |
| `Lab2/Lab2A/deliverables/verification/alb_list.txt` | `2a/deliverables/verification/aws_checks/` |
| `Lab2/Lab2A/deliverables/verification/aws_account_id.txt` | `2a/deliverables/verification/aws_checks/` |
| `Lab2/Lab2A/deliverables/verification/app_via_domain_*.txt` | `2a/deliverables/verification/aws_checks/` |
| `Lab2/Lab2A/deliverables/verification/alb_direct_*.txt` | `2a/deliverables/verification/aws_checks/` |
| `Lab2/Lab2A/deliverables/verification/gates/*` | `2a/deliverables/verification/gates/` |
| `Lab2/Lab2A/Lab2A_Verification_and_Submission_Readiness_Report.md` | `2a/deliverables/architecture/` |
| `Lab2/Lab2A/deliverables/docs/2a_*.txt` | `2a/notes/` |

### 2b — Implementation and deliverables

| Source | Destination |
|--------|-------------|
| `Lab2/capture_all_proofs.sh` | `2b/src/scripts/` |
| `Lab2/Lab2B/deliverables/proof/*.txt` | `2b/deliverables/verification/` |
| `Lab2/Lab2B/deliverables/proof/*.json` | `2b/deliverables/verification/` |
| `Lab2/Lab2B/deliverables/docs/*.txt` | `2b/deliverables/architecture/` |
| `Lab2/Lab2B/deliverables/proof/PROOF_NOTES.md` | `2b/notes/` |

### Lab-level docs

| Source | Destination |
|--------|-------------|
| `Lab2/deliverables/docs/*.md` | `SEIR_Foundations/LAB2/` and `SEIR_Foundations/LAB2/docs/` |
| `Lab2/FINAL_SUBMISSION_MAP.md` | `SEIR_Foundations/LAB2/` |
| `Lab2/LAB2_FULL_CONTEXT.md` | `SEIR_Foundations/LAB2/` |

### New files (created, not copied)

| File | Purpose |
|------|---------|
| `SEIR_Foundations/LAB2/README.md` | Lab overview, where code/proof/docs live, how to run verification |
| `SEIR_Foundations/LAB2/2a/README.md` | 2A what was built, where proof is, how to run verification |
| `SEIR_Foundations/LAB2/2a/deliverables/verification/verification_summary.md` | 2A verification summary |
| `SEIR_Foundations/LAB2/2a/deliverables/architecture/architecture_summary.md` | 2A architecture summary |
| `SEIR_Foundations/LAB2/2b/README.md` | 2B what was built, where proof is |
| `SEIR_Foundations/LAB2/2b/deliverables/submission_summary.md` | 2B submission checklist |
| `SEIR_Foundations/LAB2/2a/deliverables/verification/cli/README.md` | Purpose of cli folder |
| `SEIR_Foundations/LAB2/2a/deliverables/screenshots/README.md` | Placeholder |
| `SEIR_Foundations/LAB2/2b/deliverables/screenshots/README.md` | Placeholder |
| `SEIR_Foundations/LAB2/shared/helpers/README.md` | Purpose of shared helpers |
| `SEIR_Foundations/LAB2/shared/templates/README.md` | Purpose of shared templates |
| `SEIR_Foundations/LAB2/REORGANIZATION_MAP.md` | This file |

---

## 4. Broken paths / naming inconsistencies

- **run_all_gates_commands.sh** — Updated to write to `SEIR_Foundations/LAB2/2a/deliverables/verification/gates/` and to use `SEIR_Foundations/LAB2/2a/src/python` for gate scripts. **Run from repo root** so `REPO_ROOT` resolves correctly.
- **Terraform state** — Not copied. Apply must be run from `2a/src/terraform/` (or link/copy `terraform.tfvars`, `.terraform`, state from original Lab2A if you want to keep state).
- **Lab1/Lab1C-V2/ec2.tf** — Still referenced from docs; path is correct (repo root).
- **Original Lab2/** — Unchanged. Any scripts or docs under `Lab2/` that point to `Lab2/Lab2A/` or `Lab2/SEIR files/` still work; the **canonical** grader-friendly layout is now `SEIR_Foundations/LAB2/`.
- **DELIVERABLES_INDEX.md** — Still contains old paths (`Lab2/Lab2A/...`). For consistency, consider updating that file in `SEIR_Foundations/LAB2/` to use `SEIR_Foundations/LAB2/2a/...` and `2b/...` (same as FINAL_SUBMISSION_MAP).

---

## 5. Naming and conventions

- **Lowercase `2a` / `2b`** — Used for folder names (GitHub-friendly, no spaces).
- **verification** — Split into `cli/`, `curl_checks/`, `aws_checks/`, `gates/` for 2A only; 2B has a single `verification/` with all proof files.
- **architecture** — Holds written explanations and architecture docs (2a: report + summary; 2b: 2b_*.txt, haiku).
- **No fake results** — All verification artifacts are real copies; no placeholder proof content. Placeholders are READMEs only (e.g. screenshots, cli).
