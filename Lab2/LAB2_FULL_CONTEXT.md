# LAB 2 — FULL CONTEXT FILE (Master Review & Audit)

Generated: 2026-03-15  
Source of truth: `/Users/jordanford/armageddon/SEIR_Foundations/LAB2/`  
Every file referenced below was **read directly from disk**. No summaries or inference.

---

# 1. LAB2 File-by-File Context Review

## Core Lab Files

### 2a_lab.txt — Core requirement (MANDATORY)
Architecture: `Internet → CloudFront (+ WAF) → ALB (locked to CF) → Private EC2 → RDS`

Requires:
1. ACM cert in us-east-1 for CloudFront viewer certificate.
2. Origin cloaking layer 1: ALB SG allows only CloudFront managed prefix list (`com.amazonaws.global.cloudfront.origin-facing`).
3. Origin cloaking layer 2: ALB listener rule checks for secret header `X-Chewbacca-Growl`; no header = 403.
4. WAF moves to CloudFront (WAFv2 scope CLOUDFRONT, in us-east-1).
5. CloudFront distribution: ALB as custom origin, HTTPS-only, custom header, WAF association.
6. Route 53: domain alias to CloudFront (apex + app subdomain).

Verification CLI (students must prove all 3):
- Direct ALB → 403 (origin cloaking).
- CloudFront → 200.
- WAF at CLOUDFRONT scope (CLI query).
- DNS resolves to CloudFront IPs (`dig`).

### 2a_readme.md — Explanation (MANDATORY reading)
"Lab 2 = Origin Cloaking + CloudFront as the only public ingress."

### 2b_lab.txt — Core requirement (MANDATORY)
Configure CloudFront behaviors: static cached aggressively, API safe/not cached, cache key minimal. Terraform overlay: 6 pieces (2 cache policies, 2 ORPs, 1 response headers policy, patch distribution behaviors).

### 2b_readme.md — Explanation (MANDATORY reading)
"Lab 2B is where students stop 'using CloudFront' and start operating it correctly." Cache key vs origin forwarding are separate knobs.

### 2b_deliverables.txt — Deliverables (MANDATORY)
**Deliverable A** — Terraform:
1. Two cache policies (static aggressive + API disabled/origin-driven)
2. Two origin request policies (static minimal + API forwards headers/cookies/QS)
3. Two cache behaviors (`/static/*` + `/api/*`)
4. Be A Man Challenge: Response headers policy for explicit Cache-Control (or security headers)

**Deliverable B** — CLI proof:
- `curl -I /static/example.txt` (must show cache Hit)
- `curl -I /api/list` (must NOT cache)
- Written explanation: cache key for /api/* + forwarding rationale

**Deliverable C** — Haiku:
- Chewbacca. Japanese characters only. No English.

**Deliverable D** — Technical verification:
1. Static caching: run twice, observe `Cache-Control`, `Age` increases
2. API safety: run twice, `Age` absent or 0, fresh origin behavior
3. Query-string sanity: `?v=1` and `?v=2` → same cached object
4. Stale-read safety: POST → GET → new data appears

### 2b_class_questions.txt — Instructor scenarios (NOT student deliverables)
3 failure-injection scenarios the instructor picks per student:
- User A sees User B data (cache key excludes auth)
- Random 403 (over-forwarding)
- Cache hit ratio tanked (fragmentation)
These are live scenarios, not written homework.

### python_lab.txt — Tooling spec (LIKELY MANDATORY for Tier 1)
Lists 8 Malgus scripts. Tier 1 (required): alarm triage, Logs Insights, cache probe, origin cloak tester. Tier 2 (advanced): secret drift, Bedrock, WAF spike, cost guardrail.

### python_advanced_lab.txt — Tooling spec (Advanced lab)
Describes `malgus_cli.py` unified ops CLI. Deliverables: (1) the file, (2) terminal transcript of triage + insights + cloak-test + cf-probe, (3) 6-10 line interview talk track.

### python_advanced_labA.txt — Tooling spec (Phase IV)
`collect-evidence` subcommand for auto-IR evidence collection → Bedrock report.

---

## Be A Man Files

### 2b_Be_A_Man.txt — Umbrella (MANDATORY)
"Beron Da Saluki criteria":
1. Implements safe caching for a public GET using Cache-Control from origin
2. Demonstrates correct behavior using headers and evidence
3. Shows understanding of why Cache-Control is preferred

### 2b_Be_A_ManA.txt — Honors: Origin-Driven Caching (MANDATORY for Honors)
**App requirements:**
- `/api/public-feed`: `Cache-Control: public, s-maxage=30, max-age=0`
- `/api/list`: `Cache-Control: private, no-store`

**Terraform:** UseOriginCacheControlHeaders managed policy for `/api/public-feed`

**Proof (3-request sequence):**
1. First request → Miss
2. Second request within 30s → Hit (Age increases)
3. After 35s → Miss again

**Also prove:** `/api/list` never shows Hit + has `Cache-Control: private, no-store`

**Written:** One paragraph on origin-driven vs disabled caching.

### 2b_Be_A_ManB.txt — Honors+: Invalidation (REQUIRED for Honors+)
- Keep origin-driven caching from ManA
- Use `create-invalidation` CLI for break-glass scenarios
- Prove cache before + after invalidation (Age/x-cache)
- Policy paragraph: when invalidate vs version, why `/*` restricted

### 2b_Be_A_ManC.txt — Honors++: RefreshHit/Validators (EXTRA CREDIT)
- Add validators (ETag/Last-Modified) to one endpoint
- Observe RefreshHit after TTL expiry
- Written explanation of RefreshHit behavior
- One-paragraph takeaway

---

## Terraform Folder (SEIR_Foundations/LAB2/terraform/)

| File | Purpose | Student should |
|------|---------|----------------|
| `lab2_cloudfront_alb.tf` | CF distribution skeleton (origin, custom header, WAF) | Adapt for their project |
| `lab2_cloudfront_origin_cloaking.tf` | ALB SG (CF prefix list) + listener rule | Adapt for their project |
| `lab2_cloudfront_r53.tf` | Route 53 alias records | Adapt for their project |
| `lab2_cloudfront_shield_waf.tf` | WAFv2 at CLOUDFRONT scope | Adapt for their project |
| `lab2b_cache_correctness.tf` | 2 cache policies, 2 ORPs, 1 response headers policy, behavior snippets | Adapt for 2B deliverables |
| `lab2b_honors_origin_driven.tf` | Managed policy data sources + /api/public-feed behavior | Use for ManA |
| `lab2b_honors_plus_invalidation_action.tf` | `aws_cloudfront_create_invalidation` resource | Use for ManB |

---

# 2. Python Folder Meaning Review

## Complete Inventory

| File | What it does | Classification | Mandatory? |
|------|-------------|----------------|------------|
| `malgus_cloudfront_cache_probe.py` | Probes URL N times, prints cache-control/age/x-cache per request | **Tier 1 verification — maps directly to D.1/D.2/ManA** | **Yes** |
| `malgus_origin_cloak_tester.py` | Tests CF URL vs ALB URL, prints PASS/FAIL | **Tier 1 verification — maps to 2A cloaking proof** | **Yes** |
| `malgus_alarm_triage.py` | Pulls active CloudWatch alarms, summarizes | Tier 1 ops | Yes if Tier 1 assigned |
| `malgus_logsinsights_runner.py` | Runs Logs Insights queries, prints results | Tier 1 ops | Yes if Tier 1 assigned |
| `malgus_waf_block_spike_detector.py` | Flags spikes in WAF BLOCK counts | Tier 2 ops | Optional |
| `malgus_secret_drift_checker.py` | Compares Secrets Manager vs SSM (no passwords) | Tier 2 security | Optional |
| `malgus_bedrock_ir_generator_local.py` | Runs Bedrock report from evidence JSON | Tier 2 advanced | Optional |
| `malgus_cost_guardrail_estimator.py` | Checks invalidation counts, estimates cost | Tier 2 advanced | Optional |
| `malgus_cli.py` | Unified CLI: triage, insights, cf-probe, cloak-test, drift, bedrock-report, invalidate | **Advanced lab deliverable** | If advanced lab assigned |
| `collect-evidence.py` | Auto-collects alarms/logs/WAF/CF into evidence JSON | Phase IV | Optional |
| `sub_implementation.py` | collect-evidence wiring for malgus_cli.py | Phase IV support | Optional |
| `cli_parser.py` | Parser module for malgus_cli.py | Support | N/A |
| `run_all_gates.sh` | **Full Lab 2 gate: checks CF, WAF, R53, ACM, TLS, SG, logging. Outputs gate_result.json + badge + pr_comment** | **Grading infrastructure** | **Highly recommended** |
| `how_to_run_gates.txt` | Instructions for running `run_all_gates.sh` with env vars | Support | Read before running gate |

## Key Insights

**`run_all_gates.sh` is the grading gate.** It validates your 2A infrastructure end-to-end: CloudFront exists + enabled + deployed, aliases include domain, ACM cert ISSUED in us-east-1, WAF associated with managed rules, Route53 alias correct with CF zone ID, logging configured, origin SG not world-open, modern cache policy used. Outputs GREEN/YELLOW/RED badge. **Running this gives you an objective grade on 2A.**

**`malgus_cloudfront_cache_probe.py` directly produces ManA evidence.** Running `python malgus_cloudfront_cache_probe.py https://app.cloudyjones.xyz/api/public-feed` with 5 rounds would show the Miss→Hit→Miss sequence required by ManA.

**`malgus_origin_cloak_tester.py` directly produces 2A origin-cloaking proof.** Running it with CF URL and ALB URL gives an automated PASS/FAIL on origin cloaking.

**This changes the understanding of LAB2.** It's not just "Terraform + manual curls." The python/ folder contains operational tooling that is part of verification rigor. The gate script is potentially part of the grading pipeline.

---

# 3. Ground-Truth Requirements Reconstruction

## 2A Requirements (from 2a_lab.txt)
1. CloudFront distribution in front of ALB (custom origin, HTTPS-only, custom header)
2. Origin cloaking layer 1: ALB SG → CF prefix list only
3. Origin cloaking layer 2: ALB listener rule → secret header check → 403 default
4. WAF at CLOUDFRONT scope (us-east-1)
5. Route 53 aliases (apex + app → CloudFront)
6. ACM cert in us-east-1
7. Verification: CF → 200, ALB direct → 403, WAF at CF scope, DNS to CF

## 2B Requirements (from 2b_deliverables.txt)
**Deliverable A (Terraform):**
1. Static cache policy (aggressive: min=60s, default=86400, path-only key)
2. API cache policy (TTL 0/0/0, caching disabled)
3. Static ORP (minimal forwarding)
4. API ORP (forward cookies/QS/headers)
5. `/static/*` behavior (static CP + static ORP + response headers policy)
6. `/api/*` behavior (API CP + API ORP)
7. Response headers policy (Cache-Control on static)

**Deliverable B (CLI proof):**
1. `curl -I /static/example.txt` → cache Hit
2. `curl -I /api/list` → no cache
3. Written cache key + forwarding explanation

**Deliverable C (Haiku):**
- Japanese only, about Chewbacca

**Deliverable D (Technical verification):**
1. Static: two curls, Cache-Control + Age increases
2. API: two curls, no Age, fresh origin
3. Query string: `?v=1` and `?v=2` → same cached object
4. Stale-read safety: POST → GET → new data appears

## Be A Man Requirements
**ManA (Honors):**
- App: `/api/public-feed` with `Cache-Control: public, s-maxage=30, max-age=0`
- App: `/api/list` with `Cache-Control: private, no-store`
- Terraform: UseOriginCacheControlHeaders for public-feed
- Proof: Miss → Hit → Miss for public-feed
- Proof: no Hit + `private, no-store` for /api/list
- Written: one paragraph (origin-driven vs disabled)

**ManB (Honors+):**
- CLI: `create-invalidation` + invalidation ID
- Proof: before/after cache headers
- Written: policy paragraph

**ManC (Honors++):**
- App: send ETag/Last-Modified on one endpoint
- Proof: RefreshHit observed
- Written: one paragraph on RefreshHit

## Python/Gate Requirements
- **Tier 1 (likely mandatory):** Run cache probe + origin cloak tester. Save outputs.
- **Gate:** Run `run_all_gates.sh`. Submit gate_result.json + badge.txt.
- **Advanced lab (if assigned):** malgus_cli.py + transcript + talk track.

---

# 4. Completion Matrix

| # | Requirement | Source | Evidence in Repo | Status | Files | Next Action |
|---|------------|--------|------------------|--------|-------|-------------|
| **2A-1** | CloudFront dist + ALB origin | 2a_lab | lab2_cloudfront_alb.tf + cloudfront_distribution.txt | **Done** | Lab2A/ | — |
| **2A-2** | SG → CF prefix list | 2a_lab | lab2_cloudfront_origin_cloaking.tf | **Done** | Lab2A/ | — |
| **2A-3** | Listener rule secret header | 2a_lab | lab2_cloudfront_origin_cloaking.tf | **Done** | Lab2A/ | — |
| **2A-4** | WAF at CLOUDFRONT scope | 2a_lab | lab2_cloudfront_shield_waf.tf + waf_for_distribution.txt | **Done** | Lab2A/ | — |
| **2A-5** | Route 53 aliases | 2a_lab | lab2_cloudfront_r53.tf + route53_zones.txt | **Done** | Lab2A/ | — |
| **2A-6** | ACM in us-east-1 | 2a_lab | data.tf references acm_certificate | **Done** | Lab2A/ | — |
| **2A-7a** | CF → 200 proof | 2a_lab | proof1/2-cf-*.txt (200 from Mar 8) | **Stale** | evidence/ | Re-capture fresh curl |
| **2A-7b** | ALB direct → 403 proof | 2a_lab | app_via_domain_headers.txt = PLACEHOLDER | **Missing** | verification/ | Run curl |
| **2A-7c** | WAF at CF scope (CLI) | 2a_lab | waf_for_distribution.txt | **Done** | verification/ | — |
| **2A-7d** | DNS dig to CF | 2a_lab | proof3-dig-cloudfront-ips.txt | **Done** | evidence/ | — |
| **2A-8** | Gate: run_all_gates.sh | python/run_all_gates.sh | Not run | **Missing** | — | Run gate |
| **2B-A1** | Static cache policy | 2b_deliverables | cloudyjones_static_cp | **Done** | lab2b_cache_policies.tf | — |
| **2B-A2** | API cache policy | 2b_deliverables | cloudyjones_api_cp | **Done** | lab2b_cache_policies.tf | — |
| **2B-A3** | Static ORP | 2b_deliverables | cloudyjones_static_orp | **Done** | lab2b_cache_policies.tf | — |
| **2B-A4** | API ORP | 2b_deliverables | cloudyjones_api_orp | **Done** | lab2b_cache_policies.tf | — |
| **2B-A5** | /static/* behavior | 2b_deliverables | ordered_cache_behavior | **Done** | lab2_cloudfront_alb.tf | — |
| **2B-A6** | /api/* behavior | 2b_deliverables | ordered_cache_behavior | **Done** | lab2_cloudfront_alb.tf | — |
| **2B-A7** | Response headers policy | 2b_deliverables | cloudyjones_static_rhp | **Done (repo); apply pending** | lab2b_response_headers_policy.tf | terraform apply |
| **2B-B1** | Static proof (Hit + Age) | 2b_deliverables D.1 | proof-static-example-1.txt: 200, Hit, age=201 | **Done** | proof/ | — |
| **2B-B2** | API proof (no cache) | 2b_deliverables D.2 | proof-api-list-1.txt: 500, no Age | **Partial** | proof/ | Fix 500; re-capture |
| **2B-B3** | Written explanation | 2b_deliverables B | 2b_cache_explanation.txt | **Done** | docs/ | — |
| **2B-C** | Haiku (漢字) | 2b_deliverables C | chewbacca_haiku.txt: 3 lines, 漢字 only | **Done** | docs/ | — |
| **2B-D1** | Static x2 (Age increases) | 2b_deliverables D.1 | proof-static-example-1.txt + -2.txt | **Done** | proof/ | Re-capture after apply |
| **2B-D2** | API x2 (no Age) | 2b_deliverables D.2 | proof-api-list-1.txt: 500 | **Partial** | proof/ | Fix 500 or document |
| **2B-D3** | Query string (?v=1, ?v=2) | 2b_deliverables D.3 | Not captured | **Missing** | — | Run curls |
| **2B-D4** | Stale-read safety | 2b_deliverables D.4 | Not tested | **Missing (conditional)** | — | If API has writes |
| **ManA-1** | /api/public-feed with Cache-Control | ManA | Proof shows `cache-control: public, s-maxage=30` | **Done** | proof/ | — |
| **ManA-2** | /api/list with `private, no-store` | ManA | **App does NOT send this header** | **Missing** | — | **Patch app** |
| **ManA-3** | UseOriginCacheControlHeaders TF | ManA | lab2b_honors_origin_driven.tf | **Done** | Lab2A/ | — |
| **ManA-4** | Miss→Hit→Miss proof | ManA | Only single Miss captured | **Missing** | — | Run 3-request sequence |
| **ManA-5** | /api/list no Hit proof | ManA | 500/Error, no Hit (OK but no no-store) | **Partial** | proof/ | After patching app |
| **ManA-6** | Paragraph | ManA | 2b_honors_paragraph.txt | **Done** | docs/ | — |
| **ManB-1** | Invalidation CLI + ID | ManB | Not attempted | **Missing** | — | Run create-invalidation |
| **ManB-2** | Before/after proof | ManB | Not captured | **Missing** | — | Curls + invalidation |
| **ManB-3** | Policy paragraph | ManB | Not written | **Missing** | — | Write |
| **ManC-1** | ETag/Last-Modified | ManC | Not implemented | **Missing** | — | Patch app |
| **ManC-2** | RefreshHit evidence | ManC | Not captured | **Missing** | — | Capture |
| **ManC-3** | RefreshHit paragraph | ManC | Not written | **Missing** | — | Write |
| **Py-1** | Cache probe run | python_lab | Not run | **Missing** | — | Run |
| **Py-2** | Origin cloak test | python_lab | Not run | **Missing** | — | Run |
| **Py-3** | Gate (run_all_gates.sh) | python/ | Not run | **Missing** | — | Run |

---

# 5. Be A Man Pass

## 2b_Be_A_Man.txt (Umbrella)
**Requirements:**
1. Safe caching for public GET with origin Cache-Control → **Satisfied** (/api/public-feed works)
2. Correct behavior demonstrated via headers/evidence → **Partially satisfied** (single Miss captured, need full sequence)
3. Understanding of why Cache-Control preferred → **Satisfied** (2b_honors_paragraph.txt exists)

## 2b_Be_A_ManA.txt (Honors)
**Fully satisfied:**
- `/api/public-feed` sends `Cache-Control: public, s-maxage=30, max-age=0` ✓
- UseOriginCacheControlHeaders in Terraform ✓
- One paragraph written ✓

**NOT satisfied:**
- `/api/list` does NOT send `Cache-Control: private, no-store` — **BLOCKING**
- Miss → Hit → Miss proof not captured — **BLOCKING**
- No-Hit proof for `/api/list` is indirect (500 = not cached, but no explicit `private, no-store` header)

**Python tools that directly support ManA:** `malgus_cloudfront_cache_probe.py` with `--rounds 5 --delay 3` would produce the Miss→Hit→Miss evidence automatically.

**Status: PARTIAL. Two blocking gaps: (1) patch `/api/list` to send `private, no-store`, (2) capture 3-request proof sequence.**

## 2b_Be_A_ManB.txt (Honors+)
**Requirements:** CLI invalidation + ID, before/after cache proof, policy paragraph.
**Status: NOT ATTEMPTED.**

## 2b_Be_A_ManC.txt (Honors++)
**Requirements:** ETag/Last-Modified on one endpoint, observe RefreshHit, explanation paragraph.
**Status: NOT ATTEMPTED.**

---

# 6. Gate / Tooling / Verification Pass

| Script | Role | Mandatory? | Should Run? | Corresponds to |
|--------|------|-----------|-------------|----------------|
| **run_all_gates.sh** | Automated 2A infra grader: CF, WAF, R53, ACM, TLS, SG, logging. Outputs gate_result.json + badge.txt + pr_comment.md | **Highly recommended** — may be part of grading pipeline | **Yes** | 2A verification |
| **malgus_cloudfront_cache_probe.py** | Probes x-cache/age over multiple requests | **Tier 1 — likely required** | **Yes** | D.1, D.2, ManA Miss→Hit→Miss |
| **malgus_origin_cloak_tester.py** | CF 200 + ALB 403 automated test | **Tier 1 — likely required** | **Yes** | 2A origin cloaking proof |
| **malgus_alarm_triage.py** | CloudWatch alarm summary | Tier 1 ops | Run if assigned | Ops awareness |
| **malgus_logsinsights_runner.py** | Logs Insights automation | Tier 1 ops | Run if assigned | Ops awareness |
| **malgus_waf_block_spike_detector.py** | WAF spike detection | Tier 2 | Optional | Security ops |
| **malgus_secret_drift_checker.py** | SSM vs Secrets drift check | Tier 2 | Optional | Config safety |
| **malgus_bedrock_ir_generator_local.py** | Bedrock report from evidence | Tier 2 | Optional | AI-assisted IR |
| **malgus_cost_guardrail_estimator.py** | Cost bomb check (invalidations) | Tier 2 | Optional | Cost awareness |
| **malgus_cli.py** | Unified CLI (all above combined) | Advanced lab | If assigned | Advanced deliverable |
| **collect-evidence.py** | Auto-IR evidence bundle | Phase IV | Optional | Advanced extension |

**Key determination:**
- `run_all_gates.sh`, `malgus_cloudfront_cache_probe.py`, and `malgus_origin_cloak_tester.py` are **directly relevant** to proving lab requirements and should be run before submission.
- The remaining scripts are tools the lab provides for students to use; running them strengthens the submission but may not be strictly graded.

---

# 7. Current Repo State vs Live State

## Repo State (Lab2/Lab2A/)
- 8 Terraform files covering CF distribution, origin cloaking, WAF, R53, cache policies, ORPs, response headers policy, honors origin-driven
- All use `var.project` = `cloudyjones`, domain = `cloudyjones.xyz`
- Response headers policy and static ORP exist in repo but **have not been applied** (terraform apply pending)

## Live State
- CloudFront distribution deployed and serving traffic
- `/health`: 200
- `/api/public-feed`: 200 + correct Cache-Control header
- `/static/example.txt`: 200 + `x-cache: Hit from cloudfront` + `age: 201`
- `/api/list`: 200 (route exists) but returns 500 (DB/backend error)
- `/api/list` does NOT send `Cache-Control: private, no-store` (ManA gap)

## Mismatches
| Item | Repo | Live | Gap |
|------|------|------|-----|
| Response headers policy | In .tf file | Not applied | `terraform apply` |
| Static ORP | In .tf file | Not applied | `terraform apply` |
| `/api/list` private,no-store | Not in code | Not in response | Patch app + update ec2.tf |
| `/api/list` 500 error | Works in code | Fails at runtime | DB/backend fix |

---

# 8. Commands Still Required From Me

## 2A Proof Commands

```bash
# CF → 200 proof (fresh capture)
curl -sI "https://app.cloudyjones.xyz" | tee Lab2/Lab2A/deliverables/verification/app_via_domain_headers.txt

# ALB → 403 proof (origin cloaking)
export ALB_DNS=$(terraform -chdir=Lab2/Lab2A output -raw alb_dns)
curl -sI "https://$ALB_DNS" -k | tee Lab2/Lab2A/deliverables/verification/alb_direct_headers.txt

# DNS proof
dig app.cloudyjones.xyz A +short | tee Lab2/Lab2A/deliverables/verification/dig_cf_proof.txt

# Origin cloak tester (Tier 1 Python)
cd /Users/jordanford/armageddon/SEIR_Foundations/LAB2/python
python3 malgus_origin_cloak_tester.py "https://app.cloudyjones.xyz" "https://$ALB_DNS" | tee Lab2/Lab2A/deliverables/verification/cloak_test_result.txt
```

## 2A Gate Command

```bash
cd /Users/jordanford/armageddon/SEIR_Foundations/LAB2/python

CF_DISTRIBUTION_ID=EOCU676C9I3FL \
DOMAIN_NAME=cloudyjones.xyz \
ROUTE53_ZONE_ID=<YOUR_ZONE_ID> \
ACM_CERT_ARN=<YOUR_ACM_ARN> \
ORIGIN_SG_ID=<YOUR_ALB_SG_ID> \
./run_all_gates.sh

# Copy results
cp gate_result.json badge.txt pr_comment.md Lab2/Lab2A/deliverables/verification/
```

## 2B Proof Commands

```bash
PROOF="Lab2/Lab2B/deliverables/proof"

# D.1: Static caching (run twice)
curl -sI "https://app.cloudyjones.xyz/static/example.txt" | tee "$PROOF/proof-static-example-1.txt"
sleep 3
curl -sI "https://app.cloudyjones.xyz/static/example.txt" | tee "$PROOF/proof-static-example-2.txt"

# D.2: API (run twice)
curl -sI "https://app.cloudyjones.xyz/api/list" | tee "$PROOF/proof-api-list-1.txt"
sleep 2
curl -sI "https://app.cloudyjones.xyz/api/list" | tee "$PROOF/proof-api-list-2.txt"

# D.3: Query string sanity
curl -sI "https://app.cloudyjones.xyz/static/example.txt?v=1" | tee "$PROOF/proof-query-string-v1.txt"
curl -sI "https://app.cloudyjones.xyz/static/example.txt?v=2" | tee "$PROOF/proof-query-string-v2.txt"

# Public-feed headers
curl -sI "https://app.cloudyjones.xyz/api/public-feed" | tee "$PROOF/proof-public-feed-headers.txt"
```

## Be A Man A: Cache Probe (Python Tier 1)

```bash
cd /Users/jordanford/armageddon/SEIR_Foundations/LAB2/python
pip install requests

# ManA: Miss → Hit → Miss for public-feed (5 rounds, 8s delay)
python3 malgus_cloudfront_cache_probe.py "https://app.cloudyjones.xyz/api/public-feed" | tee Lab2/Lab2B/deliverables/proof/proof-mana-public-feed-sequence.txt

# ManA: /api/list should never Hit
python3 malgus_cloudfront_cache_probe.py "https://app.cloudyjones.xyz/api/list" | tee Lab2/Lab2B/deliverables/proof/proof-mana-api-list-nocache.txt
```

## Be A Man B: Invalidation (Honors+)

```bash
# Before: prove cached
curl -sI "https://app.cloudyjones.xyz/static/example.txt" | tee "$PROOF/proof-manb-before-1.txt"
curl -sI "https://app.cloudyjones.xyz/static/example.txt" | tee "$PROOF/proof-manb-before-2.txt"

# Invalidate
aws cloudfront create-invalidation \
  --distribution-id EOCU676C9I3FL \
  --paths "/static/example.txt" | tee "$PROOF/proof-manb-invalidation.txt"

# Wait then verify
sleep 15
curl -sI "https://app.cloudyjones.xyz/static/example.txt" | tee "$PROOF/proof-manb-after-1.txt"
```

## Be A Man C: RefreshHit (Honors++)

Requires patching app to send ETag on `/static/example.txt`, then:
```bash
curl -sI "https://app.cloudyjones.xyz/static/example.txt" | tee "$PROOF/proof-manc-1.txt"
sleep 35
curl -sI "https://app.cloudyjones.xyz/static/example.txt" | tee "$PROOF/proof-manc-2-refreshhit.txt"
```

## Infrastructure Commands

```bash
# Apply pending Terraform
cd Lab2/Lab2A
terraform plan
terraform apply

# Patch /api/list to send Cache-Control: private, no-store (via SSM)
INSTANCE_ID=i-06003411f26d02bef
aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "cd /home/ec2-user",
    "cp app.py app.py.bak.$(date +%s)",
    "python3 -c \"
path = '\''/home/ec2-user/app.py'\''
with open(path) as f:
    content = f.read()
old = '\''return list_notes()'\''
new = '\''resp = list_notes()\\n    if isinstance(resp, tuple):\\n        response = make_response(resp[0], resp[1])\\n    else:\\n        response = make_response(resp)\\n    response.headers['\\'\\''Cache-Control'\\'\\''] = '\\'\\''private, no-store'\\'\\''\\n    return response'\''
content = content.replace(old, new, 1)
with open(path, '\\''w'\\'') as f:
    f.write(content)
print('\\''Patched api_list with private,no-store'\\'')\n\"",
    "sudo systemctl restart flask-app",
    "sleep 2",
    "curl -sI http://localhost/api/list | head -10"
  ]'
```

---

# 9. Final Deliverables Map

| Category | File | Purpose | Status |
|----------|------|---------|--------|
| **Terraform** | Lab2A/lab2_cloudfront_alb.tf | CF distribution + behaviors | Ready |
| **Terraform** | Lab2A/lab2_cloudfront_origin_cloaking.tf | Origin cloaking (SG + header) | Ready |
| **Terraform** | Lab2A/lab2_cloudfront_r53.tf | Route 53 aliases | Ready |
| **Terraform** | Lab2A/lab2_cloudfront_shield_waf.tf | WAF at CLOUDFRONT scope | Ready |
| **Terraform** | Lab2A/lab2b_cache_policies.tf | 2 CPs + 2 ORPs | Ready |
| **Terraform** | Lab2A/lab2b_response_headers_policy.tf | Response headers (Be A Man) | Ready (apply pending) |
| **Terraform** | Lab2A/lab2b_honors_origin_driven.tf | UseOriginCacheControlHeaders | Ready |
| **Proof** | Lab2B/deliverables/proof/proof-static-example-1.txt | Static Hit proof | Ready |
| **Proof** | Lab2B/deliverables/proof/proof-static-example-2.txt | Static Hit proof (2nd) | Ready |
| **Proof** | Lab2B/deliverables/proof/proof-api-list-1.txt | API no-cache proof | Partial (500) |
| **Proof** | Lab2B/deliverables/proof/proof-api-list-2.txt | API no-cache proof (2nd) | Partial (500) |
| **Proof** | Lab2B/deliverables/proof/proof-public-feed-headers.txt | Public feed Cache-Control | Ready |
| **Proof** | proof-query-string-v1/v2.txt | D.3 query string | **Missing** |
| **Proof** | proof-mana-public-feed-sequence.txt | ManA Miss→Hit→Miss | **Missing** |
| **Proof** | proof-mana-api-list-nocache.txt | ManA /api/list never cached | **Missing** |
| **Proof** | gate_result.json + badge.txt | Gate output | **Missing** |
| **Proof** | cloak_test_result.txt | Python origin cloak test | **Missing** |
| **Written** | Lab2B/deliverables/docs/2b_cache_explanation.txt | Cache key + forwarding | Ready |
| **Written** | Lab2B/deliverables/docs/chewbacca_haiku.txt | 漢字 haiku | Ready |
| **Written** | Lab2B/deliverables/docs/2b_honors_paragraph.txt | Origin-driven vs disabled | Ready |
| **Written** | Lab2B/deliverables/docs/2b_be_a_man_note.txt | Be A Man mapping | Ready |
| **Written** | Lab2B/deliverables/docs/2b_done_checklist.txt | Completion checklist | Ready |
| **Written** | ManB policy paragraph | Invalidation policy | **Missing** |
| **Written** | ManC RefreshHit paragraph | RefreshHit explanation | **Missing** |
| **2A Proof** | app_via_domain_headers.txt | CF → 200 | **Missing** (placeholder) |
| **2A Proof** | alb_direct_headers.txt | ALB → 403 | **Missing** (placeholder) |

---

# 10. Final Readiness Verdict

| Component | Completion | Notes |
|-----------|-----------|-------|
| **2A Terraform** | 95% | All in repo; apply was done. |
| **2A Proof** | 60% | CF/WAF/DNS proofs exist (older); ALB 403 proof missing; gate not run. |
| **2B Terraform** | 95% | All in repo; response headers policy not yet applied. |
| **2B Proof (D.1-D.4)** | 55% | D.1 done; D.2 partial (500); D.3 missing; D.4 untested. |
| **2B Written** | 90% | Cache explanation, haiku, honors paragraph all done. |
| **Be A Man (umbrella)** | 70% | Two of three criteria met; proof sequence missing. |
| **ManA (Honors)** | 50% | TF done, paragraph done; app missing `private, no-store`; proof sequence missing. |
| **ManB (Honors+)** | 0% | Not attempted. |
| **ManC (Honors++)** | 0% | Not attempted. |
| **Python/Gate** | 0% | No scripts have been run. |

**Overall LAB2 completion: ~55-60%**

**Submission-ready: NOT YET**

**Biggest remaining risks:**
1. `/api/list` returns 500 — prevents clean D.2 and ManA proof
2. `/api/list` does not send `Cache-Control: private, no-store` — ManA hard fail
3. Response headers policy not yet applied — D.1 re-capture needed
4. No gate run — may miss grading pipeline expectations
5. No query-string proof (D.3)

**Fastest path to "mostly ready":**
1. `terraform apply` (5 min) — applies response headers policy + static ORP
2. Patch `/api/list` to send `Cache-Control: private, no-store` via SSM (5 min)
3. Run all 2B curl proof captures (10 min)
4. Run `malgus_cloudfront_cache_probe.py` for ManA public-feed sequence (5 min)
5. Run `malgus_origin_cloak_tester.py` for 2A cloaking proof (2 min)
6. Run `run_all_gates.sh` for gate badge (5 min)
7. Run 2A curl proofs (3 min)

**Time estimate to "mostly ready": ~35-40 minutes of active terminal work.**

ManB and ManC are additional time if targeting Honors+ / Honors++.

---

# 11. Self-Audit Of This Report

## What is based on actual file evidence?
- Every Terraform file in Lab2A/ was read and analyzed.
- Every proof file in Lab2B/deliverables/proof/ was read.
- Every SEIR_Foundations/LAB2 source file (2a_lab.txt, 2b_deliverables.txt, Be A Man files, python scripts, terraform templates, advanced labs) was read directly.
- Proof files show actual HTTP response headers (e.g., `x-cache: Hit from cloudfront`, `age: 201`, `cache-control: public, s-maxage=30, max-age=0`, `HTTP/2 500`).
- The gate script was read in full (604 lines).

## What is inference?
- "Gate may be part of grading pipeline" — inferred from the script outputting badge.txt and pr_comment.md, but not confirmed by any explicit statement in the lab.
- "Tier 1 scripts are likely mandatory" — inferred from `python_lab.txt` saying "required for scripters" but unclear if all students are "scripters."
- "ManA is mandatory for full credit" — inferred from it being called "Honors" and being referenced in the umbrella Be A Man criteria.
- Classification of ManB/ManC as "required for Honors+/++" is directly from the files.

## What still needs human/live confirmation?
- Whether `terraform apply` succeeds (sandbox can't run it).
- Whether the `/api/list` 500 is fixable (DB/backend issue).
- Whether the SSM patch for `private, no-store` will work.
- Whether the gate script runs clean against your actual AWS account.
- Whether the instructor considers the Python scripts mandatory for your section.

## Where might a grader still push back?
1. **`/api/list` 500**: Even though cache-safety is provable (no Age, no Hit), a grader testing the endpoint would see a broken response. The 500 makes the D.2 proof weaker than a clean 200 with `private, no-store`.
2. **No `Cache-Control: private, no-store` on `/api/list`**: ManA explicitly requires this header. Without it, the ManA claim is not defensible.
3. **No gate result**: If the grading pipeline uses `run_all_gates.sh`, a missing gate_result.json is a gap.
4. **No query-string proof (D.3)**: This is a specific deliverable that has not been captured.
5. **Response headers policy not applied**: D.1 proof was captured before this policy existed, so the current static proof doesn't show the explicit `Cache-Control: public, max-age=86400` from the response headers policy.
