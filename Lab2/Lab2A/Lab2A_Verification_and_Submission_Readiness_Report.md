# Lab2A Verification and Submission Readiness Report

**Scope:** `Lab2/Lab2A`  
**Review type:** End-to-end verification and submission readiness for student AWS lab.

---

## 1. Inventory

| File | Classification |
|------|----------------|
| `providers.tf` | terraform config |
| `variables.tf` | variable/data/output file |
| `terraform.tfvars` | variable/data/output file (values) |
| `data.tf` | variable/data/output file (data sources) |
| `outputs.tf` | variable/data/output file |
| `lab2_cloudfront_alb.tf` | DNS/CDN config (CloudFront distribution) |
| `lab2_cloudfront_origin_cloaking.tf` | security config (SG rule + listener rule) |
| `lab2_cloudfront_r53.tf` | DNS/CDN config (Route 53) |
| `lab2_cloudfront_shield_waf.tf` | security config (WAF) |
| `lab2_ec2_s3_access.tf` | security config (IAM policy) |
| `lab2b_cache_policies.tf` | DNS/CDN config (cache/origin request policies) |
| `lab2b_honors_origin_driven.tf` | DNS/CDN config (Honors cache policy reference) |
| `evidence/proof1-cf-apex-200.txt` | evidence/proof |
| `evidence/proof2-cf-app-200.txt` | evidence/proof |
| `evidence/proof3-dig-cloudfront-ips.txt` | evidence/proof |
| `evidence/proof4-cf-config.json` | evidence/proof |
| `evidence/proof5-waf-cloudfront-scope.json` | evidence/proof |

**Not present in Lab2A:** No README, no markdown, no screenshots, no `.hcl` other than lockfile. State files (`terraform.tfstate`, backups, `tfplan`) exist but are runtime artifacts, not submission deliverables.

**Summary:** 11 Terraform config/variable files, 5 evidence files, 0 documentation files.

---

## 2. Terraform Verification

### Resources being created (by this repo)

| Resource | File | Purpose |
|----------|------|---------|
| `aws_cloudfront_distribution.cloudyjones_cf01` | lab2_cloudfront_alb.tf | CDN in front of ALB; origin with custom header; path-based behaviors; WAF; viewer cert |
| `aws_security_group_rule.cloudyjones_alb_ingress_cf` | lab2_cloudfront_origin_cloaking.tf | ALB SG: ingress from CloudFront prefix list (port 80 only) |
| `aws_lb_listener_rule.cloudyjones_secret_header` | lab2_cloudfront_origin_cloaking.tf | HTTPS listener rule: forward only when `X-Chewbacca-Growl` matches |
| `aws_route53_record.cloudyjones_apex_cf` | lab2_cloudfront_r53.tf | A (alias) for apex → CloudFront |
| `aws_route53_record.cloudyjones_app_cf` | lab2_cloudfront_r53.tf | A (alias) for app subdomain → CloudFront |
| `aws_wafv2_web_acl.cloudyjones_cf_waf01` | lab2_cloudfront_shield_waf.tf | WAFv2 CLOUDFRONT scope; AWS managed Common + KnownBadInputs |
| `aws_iam_role_policy.cloudyjones_ec2_s3_read` | lab2_ec2_s3_access.tf | EC2 role policy: S3 GetObject on one bucket |
| `aws_cloudfront_cache_policy.cloudyjones_static_cp` | lab2b_cache_policies.tf | Path-only cache, aggressive TTL for /static/* |
| `aws_cloudfront_cache_policy.cloudyjones_api_cp` | lab2b_cache_policies.tf | No-cache for /api/* |
| `aws_cloudfront_origin_request_policy.cloudyjones_api_orp` | lab2b_cache_policies.tf | Forward cookies, whitelist headers, all query strings to API |
| (local) `use_origin_cache_control_headers_policy_id` | lab2b_honors_origin_driven.tf | Reference to AWS managed policy for /api/public-feed |

### Architecture (intended)

- **Viewer** → HTTPS → **CloudFront** (custom domain apex + app, WAF attached) → **ALB** (HTTPS, custom header required) → **EC2**.
- **Route 53:** Apex and `app.` are alias records to CloudFront (not to ALB).
- **Origin cloaking:** (1) ALB SG allows only CloudFront prefix list (currently port 80 in this repo). (2) Listener rule forwards only when `X-Chewbacca-Growl` equals `var.origin_secret`; otherwise request falls through to listener default (403 expected from foundation).
- **Path-based cache:** `/api/public-feed` → origin-driven cache (managed policy); `/api/*` → no cache (custom policy + ORP); `/static/*` → aggressive cache (custom policy); default → CachingDisabled.

### Internal consistency

- **References:** All resource references (data.aws_lb, data.aws_lb_listener, data.aws_route53_zone, data.aws_acm_certificate, aws_wafv2_web_acl, cache/origin-request policies, local) resolve. No circular or broken references.
- **Providers:** WAF and ACM use `provider = aws.us_east_1`; CloudFront distribution and other resources use default provider. Correct for CLOUDFRONT-scope WAF and CloudFront viewer certs.
- **Ordering:** `/api/public-feed` is declared before `/api/*` in `ordered_cache_behavior` blocks, so path matching is correct.

### Hardcoded values that should be parameterized

1. **`lab2_ec2_s3_access.tf`**
   - `role = "cloudyjones-ec2-role01"` — should use something like `"${var.project}-ec2-role01"` or a variable.
   - `Resource = "arn:aws:s3:::cloudyjones-alb-logs-583001104385/*"` — bucket name and account ID are hardcoded. Should use variable or data source so it works for other projects/accounts.
2. **`lab2b_honors_origin_driven.tf`** — Policy ID `83da9c7e-98b4-4e11-a168-04f0df8e2c65` is the AWS managed “UseOriginCacheControlHeaders”; acceptable to keep as-is (managed policy ID is fixed).
3. **`lab2_cloudfront_alb.tf`** — Managed policy IDs for default behavior (`4135ea2d-...`, `b689b0a8-...`) are AWS constants; acceptable.

### Broken or incomplete

- **Default 403 for ALB:** The comments in `lab2_cloudfront_origin_cloaking.tf` say requests that don’t match the header rule “fall through to the default 403.” That default action is **not** defined in this repo; it must be set on the HTTPS listener by the **foundation lab**. If the foundation listener’s default action is not “fixed response 403,” direct ALB access would not be blocked by this lab alone.
- **Security group port vs origin protocol:**  
  - `lab2_cloudfront_alb.tf`: `origin_protocol_policy = "https-only"`, so CloudFront talks to the ALB on **port 443**.  
  - `lab2_cloudfront_origin_cloaking.tf`: `aws_security_group_rule` allows only **port 80** from the CloudFront prefix list.  
  So either (1) the foundation already has an ingress rule allowing 443 (e.g. from 0.0.0.0/0 or from CloudFront), and this lab only adds 80-from-CF—in which case the “network” part of origin cloaking may not fully restrict 443—or (2) the rule should allow 443 from CloudFront. As written, the Terraform does not add a 443-from-CloudFront rule; if the foundation removed 0.0.0.0/0 on 443, CloudFront would not be able to reach the ALB. **Verdict:** Port mismatch; should be verified and fixed (e.g. add or change rule to 443) for a correct origin-cloaking story.

### Foundation dependencies (outside this repo)

All of the following are **data lookups**; this lab assumes they already exist from a prior “foundation” lab:

- **ALB:** `data.aws_lb.cloudyjones_alb01` — name `"${var.project}-alb01"`.
- **HTTPS listener (443):** `data.aws_lb_listener.cloudyjones_https` — default action (e.g. 403) must be set there.
- **ALB security group:** `data.aws_security_group.cloudyjones_alb_sg01` — name `"${var.project}-alb-sg01"`.
- **Target group:** `data.aws_lb_target_group.cloudyjones_tg01` — name `"${var.project}-tg01"`.
- **Route 53 hosted zone:** `data.aws_route53_zone.cloudyjones_zone01` — `var.domain_name` (e.g. `cloudyjones.xyz`).
- **ACM certificate (us-east-1):** `data.aws_acm_certificate.cloudyjones_cert` — issued cert for `var.domain_name`.
- **EC2 IAM role (for lab2_ec2_s3_access.tf):** Not a data source; name is hardcoded. Role `cloudyjones-ec2-role01` must exist.

None of this is documented in Lab2A. A grader or new clone would not know what “foundation lab” must provide.

### Lab2A design checklist (Terraform support)

| Requirement | Supported in Terraform | Notes |
|-------------|------------------------|--------|
| CloudFront in front of ALB | Yes | Single distribution, ALB as origin |
| WAF at CloudFront scope | Yes | `web_acl_id` on distribution; WAF in us-east-1 |
| Route 53 alias records | Yes | Apex and app. to CloudFront |
| Origin cloaking / custom header | Yes | Custom header on origin; listener rule on ALB |
| Path-based cache behavior | Yes | Four behaviors: /api/public-feed, /api/*, /static/*, default |
| /api/public-feed behavior | Yes | Origin-driven cache (managed policy) |
| /api/* no-cache | Yes | Custom cache policy TTL 0/0/0 + ORP |
| /static/* aggressive caching | Yes | Custom policy path-only, 1d default TTL |
| Honors / origin-driven | Yes | UseOriginCacheControlHeaders for /api/public-feed |

**Conclusion:** Terraform is **largely correct and coherent** and matches the intended Lab 2A design, with two caveats: (1) SG rule allows port 80 while origin uses HTTPS (443)—needs alignment; (2) default 403 and full SG lockdown depend on foundation lab.

---

## 3. Evidence / Proof Review

### proof1-cf-apex-200.txt

- **Content:** HTTP/2 200 response; headers include `via: 1.1 ... cloudfront.net`, `x-cache: Miss from cloudfront`, `x-amz-cf-pop: IAD61-P10`; body: “cloudyjones — private EC2, Section A”.
- **What it proves:** Apex domain (or CloudFront apex alias) returns 200 through CloudFront; request reached origin (Werkzeug); CloudFront is in the path.
- **Strength:** Strong for “CloudFront distribution is serving apex.”
- **Maps to lab goals:** Yes — demonstrates CloudFront in front and DNS/alias working for apex.
- **Outdated/inconsistent:** No; consistent with current Terraform.

### proof2-cf-app-200.txt

- **Content:** Same structure as proof1; different `via`/`x-amz-cf-id`; body same.
- **What it proves:** App subdomain returns 200 through CloudFront.
- **Strength:** Strong for “CloudFront serving app subdomain.”
- **Maps to lab goals:** Yes — demonstrates both aliases (apex + app) working.
- **Outdated/inconsistent:** No.

### proof3-dig-cloudfront-ips.txt

- **Content:** Four IP addresses (e.g. 3.170.42.51, 3.170.42.58, …).
- **What it proves:** Unclear without context. Could be output of `dig apex` or `dig app` showing that the domain resolves to CloudFront edge IPs (not ALB IPs).
- **Strength:** Weak as standalone—no command shown, no comparison to “expected” or “ALB IPs,” no domain name in the file.
- **Maps to lab goals:** Partially—if the lab asks “prove DNS points to CloudFront,” this could support it if the grader infers that these are CloudFront IPs and that the domain was resolved.
- **Recommendation:** Add one line stating the command (e.g. `dig +short cloudyjones.xyz`) and that these are CloudFront edge IPs.

### proof4-cf-config.json

- **Content:** Snippet with WAF ARN and Origins list; origin domain is the ALB DNS name; `"Protocol": "http-only"`.
- **What it proves:** CloudFront distribution exists; origin is the ALB; WAF is attached.
- **Strength:** Good for “WAF attached” and “origin is ALB.” Protocol field is ambiguous (could be API display quirk).
- **Maps to lab goals:** Yes.
- **Inconsistency:** Terraform has `origin_protocol_policy = "https-only"`. proof4 shows `"Protocol": "http-only"`. Either the config was changed after the proof was captured, or the API/CLI represents it differently. Worth a one-line note in docs or re-capture to avoid grader confusion.

### proof5-waf-cloudfront-scope.json

- **Content:** List WebACLs response; one Web ACL named `cloudyjones-cf-webacl01`, description “WAF for CloudFront distribution - CLOUDFRONT scope,” ARN in `us-east-1` with `global` (CLOUDFRONT scope).
- **What it proves:** WAF exists and is CLOUDFRONT-scoped (global).
- **Strength:** Strong.
- **Maps to lab goals:** Yes — WAF at CloudFront scope.
- **Outdated/inconsistent:** No.

### Missing proof (required gap)

- **Direct ALB 403:** The design and `outputs.tf` state that after lockdown, “curl this [ALB DNS] directly” should return 403. There is **no evidence file** showing a direct request to the ALB DNS and a 403 response. Without it, a grader cannot verify that origin cloaking (no direct ALB access) is working. **This is a required gap for submission:** add a proof file (e.g. `evidence/proof-alb-direct-403.txt` or similar) containing the command and full response (e.g. `curl -I https://<alb_dns>` → 403).

### Cache behavior evidence

- No proof file shows cache hit vs miss for `/api/public-feed`, `/api/*`, or `/static/*`. Not strictly required for “submission ready” if the lab rubric doesn’t ask for it, but would strengthen the story. Optional improvement.

**Evidence summary:** Proofs 1, 2, 5 are strong and map clearly to CloudFront, aliases, and WAF. Proof 3 is weak without context. Proof 4 is good but has a protocol discrepancy with Terraform. **Critical gap:** No proof that direct ALB access returns 403.

---

## 4. Documentation Readiness

- **README or equivalent:** **None.** There is no README, no `LAB2A.md`, no instructions file in `Lab2A`.
- **What was built:** Only inferable from Terraform comments and file names. No single place that states “Lab2A implements CloudFront in front of ALB, WAF at edge, origin cloaking, path-based caching, R53 to CF.”
- **Prerequisites / dependencies:** Not documented. A reviewer would not know that ALB, listener, SG, target group, R53 zone, ACM cert (and optionally EC2 role) must exist from a “foundation lab,” or what their names must be.
- **How to deploy:** Not documented (e.g. `terraform init`, `plan`, `apply`, how to set `origin_secret` without committing it).
- **How to test:** Not documented. No steps for “hit apex, hit app, check headers, verify WAF, verify direct ALB 403.”
- **What each proof file means:** Not documented. Proof3 in particular needs a one-line explanation; proof4’s protocol vs Terraform could use a note.
- **Assumptions from prior labs:** Not stated.

**Verdict:** Lab2A is **not** documented well enough for a reviewer or grader to understand scope, prerequisites, or how to reproduce. Documentation readiness is **low**.

---

## 5. Submission Readiness Check

- **Is Lab2A technically implemented well enough to submit?**  
  **Mostly yes.** Terraform is coherent and implements CloudFront, WAF, R53, origin cloaking (header + SG rule), and path-based caching including /api/public-feed and honors. Two issues: (1) SG rule allows port 80 only while origin uses 443—needs verification/fix; (2) EC2/S3 policy uses hardcoded role and bucket. Default 403 depends on foundation. So: **technically close, but with fixable gaps.**

- **Is Lab2A documented well enough to submit?**  
  **No.** No README or doc; prerequisites and proof meanings are unexplained. Many rubrics require “what you built + how to run it.”

- **Is Lab2A verified well enough to submit?**  
  **No.** Missing proof that direct ALB access returns 403. proof3 is weak without context. Without a deliverables list in-repo we can’t tick “all proofs present,” but the 403 proof is explicitly called out in `outputs.tf` and is absent.

- **What would a grader or senior reviewer still question?**  
  (1) No README. (2) No proof of ALB 403. (3) proof3—what command, what does it prove? (4) proof4 “http-only” vs Terraform “https-only.” (5) SG rule port 80 vs origin 443. (6) Hardcoded role and bucket in `lab2_ec2_s3_access.tf`. (7) What is the “foundation lab” and what must it provide?

- **What would fail review today?**  
  (1) Missing documentation (README). (2) Missing evidence that direct ALB returns 403. (3) If the rubric requires “no hardcoded account/project values,” the EC2/S3 policy would fail. (4) If the rubric requires “origin cloaking fully implemented and proven,” the missing 403 proof and the SG port mismatch would be issues.

- **Polish vs blocking:**  
  **Blocking:** No README (or equivalent), no direct ALB 403 proof. **Recommended:** Fix SG port (443 from CloudFront or document why 80 is correct), parameterize EC2 role and bucket, add one-line context for proof3 and a note for proof4. **Polish:** Cache hit/miss proofs, optional verification script.

---

## 6. Required Fixes Before Submission

### Blocking fixes

1. **Add a README** (e.g. `Lab2A/README.md`) that includes:
   - What was built (CloudFront in front of ALB, WAF at edge, R53 alias records, origin cloaking, path-based cache behaviors including /api/public-feed and /static/*).
   - Prerequisites: foundation lab must provide ALB (`{project}-alb01`), HTTPS listener on 443 with default action 403, ALB SG (`{project}-alb-sg01`), target group (`{project}-tg01`), Route 53 hosted zone for `domain_name`, ACM cert in us-east-1 for `domain_name`. Optionally EC2 role if using `lab2_ec2_s3_access.tf`.
   - How to deploy: `terraform init`, `terraform plan`, `terraform apply`; set `origin_secret` via `TF_VAR_origin_secret` or a non-committed tfvars.
   - How to test: e.g. curl apex and app (expect 200 via CloudFront); curl ALB DNS directly (expect 403).
   - What each evidence file proves and how it was generated (at least for proof3 and proof4; and that proof 403 is required).

2. **Add proof that direct ALB access returns 403.** Create a file (e.g. `evidence/proof-alb-direct-403.txt`) containing the command used (e.g. `curl -I https://$(terraform output -raw alb_dns)`) and the full response showing HTTP 403. This matches the requirement stated in `outputs.tf`.

### Recommended fixes

3. **Align security group rule with origin protocol.** Either (a) add an ingress rule allowing **port 443** from the CloudFront prefix list (and remove or document the port-80 rule if it’s redundant), or (b) if the design is intentionally HTTP to origin, set `origin_protocol_policy` to match and document why. As written, 80 vs 443 is inconsistent.

4. **Parameterize `lab2_ec2_s3_access.tf`.** Use `var.project` (or a variable) for the role name (e.g. `"${var.project}-ec2-role01"`). Use a variable or data source for the S3 bucket ARN/name so it’s not hardcoded with account ID.

5. **Clarify proof3.** In README or inside `evidence/proof3-dig-cloudfront-ips.txt`, add one line: e.g. “Output of `dig +short <apex or app domain>` — these are CloudFront edge IPs.”

6. **Note proof4 vs Terraform.** In README or in evidence, add one line that Terraform configures HTTPS to origin; if proof4 shows “http-only,” it may be API/CLI display or from an earlier run.

### Optional polish

7. Move `origin_secret` out of `terraform.tfvars` if the rubric forbids secrets in repo (e.g. use `TF_VAR_origin_secret` and add `terraform.tfvars` to `.gitignore` if it still contains secrets).
8. Add a short “Evidence checklist” in the README mapping each proof to a lab goal.
9. Remove or update the outdated comment in `outputs.tf` (“will need to update outputs file…”).

---

## 7. Final Verdict

| Metric | Percentage | Notes |
|--------|------------|--------|
| **Technical completion** | ~85% | Terraform is complete and coherent; SG port vs 443 and hardcoded EC2/S3 are fixable; default 403 is external. |
| **Documentation completion** | ~5% | No README or supporting doc; only inline Terraform comments. |
| **Verification completion** | ~70% | Five proofs present; one critical gap (direct ALB 403); proof3 weak. |
| **Overall submission readiness** | ~55% | Strong infra and most evidence; missing docs and one required proof. |

**Status: Nearly ready** — not “ready” because of missing README and missing ALB 403 proof; not “not ready” because the implementation and most evidence are in good shape.

**Fastest path to submission ready:**

1. Add `Lab2A/README.md` with the blocking items above (what was built, prerequisites, deploy, test, evidence meaning).
2. Capture and add `evidence/proof-alb-direct-403.txt` (curl ALB DNS → 403).
3. Optionally fix the SG rule to 443 from CloudFront and parameterize the EC2/S3 policy; then re-run apply and keep evidence consistent.

After (1) and (2), Lab2A would be in a **ready** state for a typical submission; (3) would strengthen review and avoid grader questions.
