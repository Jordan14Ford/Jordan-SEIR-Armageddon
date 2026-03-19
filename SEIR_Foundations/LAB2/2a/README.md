# 2A — CloudFront, WAF, Route 53, ALB (Origin Cloaking)

Lab 2 Part A: CDN in front of ALB, custom domain, HTTPS, WAF, and origin cloaking.

---

## What was built

- **CloudFront** distribution with path-based behaviors (`/api/public-feed`, `/api/*`, `/static/*`, default).
- **Route 53** A (alias) records for apex and `app.` → CloudFront.
- **ACM** viewer certificate; **WAF** WebACL (CLOUDFRONT scope) attached to the distribution.
- **Origin cloaking:** ALB security group allows only CloudFront prefix list; listener rule requires custom header; direct ALB access fails (timeout/403).

---

## Where the proof is

| Category | Path |
|----------|------|
| **curl / dig** | [deliverables/verification/curl_checks/](deliverables/verification/curl_checks/) |
| **AWS CLI** | [deliverables/verification/aws_checks/](deliverables/verification/aws_checks/) |
| **Gates** | [deliverables/verification/gates/](deliverables/verification/gates/) |
| **Architecture** | [deliverables/architecture/](deliverables/architecture/) |

See [deliverables/verification/verification_summary.md](deliverables/verification/verification_summary.md) and [deliverables/architecture/architecture_summary.md](deliverables/architecture/architecture_summary.md) for summaries.

---

## How to run verification

- **All gates:** From repo root, run `SEIR_Foundations/LAB2/2a/src/scripts/run_all_gates_commands.sh` (set `DB_ID` and `SECRET_ID` as needed).
- **Terraform:** From `src/terraform/`, run `terraform init && terraform plan`.
- **Curl/dig proofs:** Use `src/scripts/capture_curl_proofs.sh` against your domain; save outputs into `deliverables/verification/curl_checks/`.

---

## Final deliverables

- **Source:** `src/terraform/`, `src/scripts/`, `src/python/` (gate scripts and helpers).
- **Evidence:** `deliverables/verification/` (cli, curl_checks, aws_checks, gates).
- **Docs:** `deliverables/architecture/`, `notes/`.
