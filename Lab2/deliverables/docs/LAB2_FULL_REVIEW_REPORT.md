# Lab 2 — Full Review Report

A single document for reviewing the entirety of Lab 2: names, setup, details, reasoning, and structure. Use this to validate the lab end-to-end.

---

## 1. Overview

| Part | Purpose |
|------|---------|
| **Lab 2A** | Origin cloaking + CloudFront as the only public ingress. Internet → CloudFront (+ WAF) → ALB (locked to CloudFront) → private EC2 → RDS. No direct ALB access; DNS and WAF at the edge. |
| **Lab 2B** | CloudFront cache correctness: static content cached aggressively, API not cached (or origin-driven), cache key and origin forwarding configured correctly, with proof and written explanations. |
| **Be A Man** | Optional tiers: (A) response headers policy + origin-driven caching for a public endpoint; (B) invalidation procedure and policy; (C) validators (ETag/Last-Modified), 304, and RefreshHit understanding. |

This lab uses **one CloudFront stack** for both 2A and 2B; Terraform lives under `Lab2/Lab2A/` and includes 2B behaviors and policies.

---

## 2. Architecture (Flow and Components)

```
Internet
   │
   ▼
CloudFront (viewer HTTPS, WAF attached)
   │  • Aliases: cloudyjones.xyz, app.cloudyjones.xyz
   │  • Origin: ALB (http-only, custom header X-Chewbacca-Growl)
   │  • Behaviors: /api/public-feed → origin-driven; /api/* → no cache; /static/* → aggressive + RHP; default → CachingDisabled
   │
   ▼
ALB (only reachable from CloudFront prefix list + secret header)
   │  • SG: ingress from com.amazonaws.global.cloudfront.origin-facing only
   │  • Listener rule: forward only if X-Chewbacca-Growl matches var.origin_secret
   │
   ▼
EC2 (Flask) — /api/list, /api/public-feed, /static/example.txt, /health, etc.
   │
   ▼
RDS (optional; /api/list may 500 if DB unreachable)
```

- **WAF:** CLOUDFRONT scope, us-east-1; AWS managed Common + KnownBadInputs. Attached to the distribution via `web_acl_id`.
- **DNS:** Route53 A (alias) for apex and `app.` to the CloudFront distribution; no records pointing at the ALB for public access.
- **Origin protocol:** CloudFront → ALB is **http-only** (no TLS to origin). TLS is viewer → CloudFront only.

---

## 3. Naming Conventions

### 3.1 Project and domain

| Item | Value | Where used |
|------|--------|-------------|
| **Project prefix** | `cloudyjones` | `var.project` default in `Lab2A/variables.tf`; prefixed to almost all resource names. |
| **Root domain** | `cloudyjones.xyz` | `var.domain_name`; Route53 zone, ACM cert, CloudFront aliases. |
| **App hostname** | `app.cloudyjones.xyz` | Second CloudFront alias; used in proof capture and curl examples. |

So in the console you see names like: `cloudyjones-cf01`, `cloudyjones-alb01`, `cloudyjones-static-cache-policy`, `cloudyjones-cf-webacl01`.

### 3.2 Terraform resource names (pattern)

- **CloudFront:** `aws_cloudfront_distribution.cloudyjones_cf01`
- **WAF:** `aws_wafv2_web_acl.cloudyjones_cf_waf01`
- **Route53:** `aws_route53_record.cloudyjones_apex_cf`, `aws_route53_record.cloudyjones_app_cf`
- **Origin cloaking:** `aws_security_group_rule.cloudyjones_alb_ingress_cf`, `aws_lb_listener_rule.cloudyjones_secret_header`
- **Cache/ORP/RHP:** `cloudyjones_static_cp`, `cloudyjones_api_cp`, `cloudyjones_static_orp`, `cloudyjones_api_orp`, `cloudyjones_static_rhp`
- **Data sources:** `data.aws_lb.cloudyjones_alb01`, `data.aws_security_group.cloudyjones_alb_sg01`, `data.aws_route53_zone.cloudyjones_zone01`, `data.aws_acm_certificate.cloudyjones_cert`, etc.

Naming is consistent: `cloudyjones_` + short suffix (e.g. `_cf01`, `_alb_ingress_cf`, `_static_cp`).

### 3.3 Secret header (lab requirement)

- **Header name:** `X-Chewbacca-Growl` (from lab spec; “Chewbacca” theme).
- **Value:** From `var.origin_secret` (sensitive). CloudFront adds it on every request to the ALB; the ALB listener rule allows forwarding only when it matches.

### 3.4 File naming (Terraform)

| File | Role |
|------|------|
| `lab2_cloudfront_alb.tf` | CloudFront distribution, origin, behaviors (including 2B paths). |
| `lab2_cloudfront_origin_cloaking.tf` | ALB SG rule (CloudFront prefix list), listener rule (secret header). |
| `lab2_cloudfront_r53.tf` | Route53 A alias records to CloudFront. |
| `lab2_cloudfront_shield_waf.tf` | WAF WebACL, CLOUDFRONT scope, us-east-1. |
| `lab2b_cache_policies.tf` | Cache policies (static, API) and origin request policies (static, API). |
| `lab2b_response_headers_policy.tf` | Response headers policy for /static/* (Cache-Control). |
| `lab2b_honors_origin_driven.tf` | Local for AWS managed policy ID (UseOriginCacheControlHeaders) for /api/public-feed. |
| `data.tf` | Data sources: ALB, listener, ALB SG, Route53 zone, ACM cert. |
| `variables.tf` | project, aws_region, origin_secret, domain_name. |
| `outputs.tf` | cloudfront_domain, cloudfront_distribution_id, alb_dns, waf_arn, hosted_zone_id. |
| `providers.tf` | aws (default region), aws.us_east_1 (for WAF + ACM). |

So: **lab2_** = 2A (CloudFront/ALB/WAF/DNS), **lab2b_** = 2B (cache/ORP/RHP/honors).

### 3.5 Proof and deliverables naming

- **2A proof:** `proof1-cf-apex-200.txt`, `proof2-cf-app-200.txt`, `proof3-dig-cloudfront-ips.txt`, `proof4-cf-config.json`, `proof5-waf-cloudfront-scope.json`, `alb_direct_blocked.txt`, `dig_cf_proof.txt`.
- **2B proof:** `proof-static-example-1.txt`, `proof-static-example-2.txt`, `proof-static-qs-v1.txt`, `proof-static-qs-v2.txt`, `proof-api-list-1.txt`, `proof-api-list-2.txt`, `proof-public-feed-miss.txt`, `proof-public-feed-hit.txt`, `proof-invalidation-*.txt`/`.json`, `proof-manc-*.txt`.
- **Docs:** `2b_cache_explanation.txt`, `2b_honors_paragraph.txt`, `2b_manb_invalidation_policy.txt`, `2b_manc_refreshhit_explanation.txt`, `chewbacca_haiku.txt`.

---

## 4. Setup (Terraform and Dependencies)

### 4.1 Where Terraform lives

- **Lab 2 Terraform (2A + 2B):** `Lab2/Lab2A/`. No separate “2B Terraform” directory; 2B is implemented by adding cache/ORP/RHP and behaviors in the same distribution.
- **Assumptions (existing resources):** ALB `cloudyjones-alb01`, ALB SG `cloudyjones-alb-sg01`, HTTPS listener on 443, target group `cloudyjones-tg01`, Route53 hosted zone for `cloudyjones.xyz`, ACM cert (us-east-1) for `cloudyjones.xyz`. These are referenced via `data` in `data.tf` and in `lab2_cloudfront_origin_cloaking.tf`.

### 4.2 Providers

- **Default `provider "aws"`:** `var.aws_region` (default `us-east-1`) — used for ALB, SG, Route53, CloudFront distribution, cache policies, etc.
- **`provider "aws" { alias = "us_east_1" }`:** Used for WAF (CLOUDFRONT scope) and ACM cert lookup; required by AWS for global/CloudFront resources.

### 4.3 Variables (inputs)

| Variable | Default | Purpose |
|----------|---------|---------|
| `project` | `cloudyjones` | Prefix for resource names. |
| `aws_region` | `us-east-1` | Primary deployment region. |
| `origin_secret` | (none; required) | Value for X-Chewbacca-Growl; must match between CloudFront custom header and ALB rule. |
| `domain_name` | `cloudyjones.xyz` | Root domain for Route53 and ACM. |

### 4.4 Data sources (no resources created here)

- `data.aws_lb.cloudyjones_alb01` — ALB DNS name for CloudFront origin.
- `data.aws_lb_listener.cloudyjones_https` — To attach the secret-header listener rule.
- `data.aws_security_group.cloudyjones_alb_sg01` — To add the CloudFront prefix-list ingress rule.
- `data.aws_route53_zone.cloudyjones_zone01` — To create A records.
- `data.aws_acm_certificate.cloudyjones_cert` (provider us_east_1) — Viewer certificate for CloudFront.
- `data.aws_ec2_managed_prefix_list.cloudfront` — `com.amazonaws.global.cloudfront.origin-facing`.
- `data.aws_lb_target_group.cloudyjones_tg01` — For the listener rule forward action.

### 4.5 App (Flask) location

- **Code:** `Lab1/Lab1C-V2/ec2.tf` (user_data script that writes `app.py` and runs the Flask app).
- **Routes relevant to Lab 2:** `/api/list` (Cache-Control: private, no-store), `/api/public-feed` (Cache-Control: public, s-maxage=30, max-age=0), `/static/example.txt` (ETag + Last-Modified for ManC). Lab 2 does not create EC2; it assumes an existing ALB/EC2 stack and adds CloudFront + behaviors + app routes in the same repo.

---

## 5. Details (Behaviors, Policies, and Config)

### 5.1 CloudFront behavior order (critical)

Behaviors are evaluated in **order**; first match wins. So more specific paths must come before broader ones.

| Order | Path pattern | Cache policy | Origin request policy | Response headers | Purpose |
|-------|----------------|--------------|------------------------|------------------|---------|
| 1 | `/api/public-feed` | UseOriginCacheControlHeaders (managed) | `cloudyjones_api_orp` | — | Honors A: origin-driven TTL (e.g. 30s). |
| 2 | `/api/*` | `cloudyjones_api_cp` (TTL 0/0/0) | `cloudyjones_api_orp` | — | API: no caching. |
| 3 | `/static/*` | `cloudyjones_static_cp` | `cloudyjones_static_orp` | `cloudyjones_static_rhp` | Static: aggressive cache + explicit Cache-Control. |
| (default) | (default) | CachingDisabled (managed) | AllViewerExceptHostHeader (managed) | — | Fallback; all methods forwarded. |

If `/api/*` were before `/api/public-feed`, public-feed would never get origin-driven caching.

### 5.2 Cache policies (lab2b_cache_policies.tf)

- **cloudyjones_static_cp:** min_ttl 60, default_ttl 86400, max_ttl 2592000. Cache key: path only (no cookies, no headers, no query strings). So `?v=1` and `?v=2` hit the same cached object.
- **cloudyjones_api_cp:** min/default/max_ttl = 0. Nothing cached; every request goes to origin.

### 5.3 Origin request policies

- **cloudyjones_static_orp:** None for cookies, headers, query strings — minimal forwarding for /static/*.
- **cloudyjones_api_orp:** Cookies: all. Headers: whitelist (Content-Type, Accept, Origin). Query strings: all. Forwarding is for origin logic only; cache key for /api/* is irrelevant because TTL is 0.

### 5.4 Response headers policy (Be A Man A.4)

- **cloudyjones_static_rhp:** Adds `Cache-Control: public, max-age=86400` (override) on /static/* responses so CloudFront sends a consistent cache directive to clients.

### 5.5 Origin cloaking (two layers)

1. **Network:** ALB security group ingress allows only the CloudFront managed prefix list (`com.amazonaws.global.cloudfront.origin-facing`) on port 80. Any other IP (e.g. direct curl to ALB DNS) is dropped at the network layer (connection timeout, no 403).
2. **Application:** ALB listener rule (priority 1) forwards only when `X-Chewbacca-Growl` equals `var.origin_secret`. Otherwise the request falls through to the default action (403). So even a custom CloudFront in front of this ALB would need the secret header.

### 5.6 WAF

- One WebACL: `cloudyjones_cf_waf01`, scope CLOUDFRONT, in us-east-1. Rules: AWSManagedRulesCommonRuleSet, AWSManagedRulesKnownBadInputsRuleSet. Attached to the distribution via `web_acl_id` in `lab2_cloudfront_alb.tf`.

### 5.7 Flask response headers (for review)

- `/api/list`: `Cache-Control: private, no-store` — never cache.
- `/api/public-feed`: `Cache-Control: public, s-maxage=30, max-age=0` — CDN can cache 30s.
- `/static/example.txt`: Body plus `ETag` and `Last-Modified` (no Cache-Control in app; CloudFront RHP adds Cache-Control for /static/*).

---

## 6. Reasoning (Why Things Are This Way)

| Decision | Reason |
|----------|--------|
| **CloudFront in front of ALB** | Single public entry point; WAF and TLS at the edge; ALB not exposed to the internet. |
| **Two-layer origin cloaking** | Defense in depth: SG blocks at network layer; header rule blocks at application layer if someone reuses CloudFront IPs. |
| **http-only to origin** | Avoids origin TLS (cert/hostname) complexity; traffic is already inside AWS. Spec and docs allow HTTP to origin. |
| **Path order /api/public-feed before /api/*** | CloudFront matches first path in order; /api/* would otherwise catch public-feed and apply no-cache. |
| **Separate cache policy vs origin request policy** | Cache key = what makes two requests “the same”; ORP = what is sent to origin. They can differ (e.g. forward Auth but don’t cache on it for API). |
| **Static: path-only cache key** | Avoids cache fragmentation from query strings; ?v=1 and ?v=2 correctly share one object. |
| **API: TTL 0/0/0** | Safe default: no risk of serving one user’s data to another or stale reads; optional origin-driven path (/api/public-feed) is explicit. |
| **UseOriginCacheControlHeaders for /api/public-feed** | Lets the app control TTL via Cache-Control (e.g. s-maxage=30) instead of hardcoding in Terraform. |
| **RHP for /static/*** | Lab requires “response headers policy for explicit Cache-Control on static”; ensures clients and caches see a consistent directive. |
| **WAF CLOUDFRONT scope in us-east-1** | AWS requirement for WebACLs attached to CloudFront. |
| **Proof in Lab2A/ and Lab2B/ deliverables** | 2A proof = infrastructure (CF 200, DNS, WAF, ALB blocked); 2B proof = caching (static, API, public-feed, invalidation, ManC). One hub under Lab2/deliverables/docs/ points to both. |

---

## 7. Repo and Deliverables Structure

### 7.1 High-level layout

```
Lab2/
├── FINAL_SUBMISSION_MAP.md          # Points to deliverables hub
├── LAB2_FULL_CONTEXT.md             # Long-form context (optional)
├── deliverables/                    # Submission hub
│   ├── README.md                    # Start here; points to GRADER_START_HERE
│   ├── docs/                        # All key docs for review
│   │   ├── GRADER_START_HERE.md     # Ordered steps for graders
│   │   ├── DELIVERABLES_INDEX.md    # Every deliverable, what it proves, status
│   │   ├── FINAL_SUBMISSION_MAP.md  # Checklist: Terraform, proof, gates, status
│   │   ├── REMAINING_GAPS_CHECKLIST.md
│   │   ├── LAB2_REMAINING_WORK_REPORT.md
│   │   └── LAB2_FULL_REVIEW_REPORT.md  # This file
│   ├── proof/README.md              # Points to Lab2A/Lab2B proof paths
│   ├── verification/README.md       # Points to Lab2A verification
│   ├── gates/README.md              # Points to Lab2A gates
│   └── summaries/README.md          # Points to LAB2_FULL_CONTEXT, etc.
├── Lab2A/                           # Terraform + 2A proof + verification
│   ├── *.tf                         # All 2A + 2B Terraform
│   ├── deliverables/
│   │   ├── proof/                   # 2A proof files
│   │   ├── verification/            # AWS CLI outputs, gate runs
│   │   └── docs/                    # 2A-specific docs
│   └── scripts/                     # capture_curl_proofs.sh, etc.
├── Lab2B/                           # No Terraform; 2B proof + written docs
│   └── deliverables/
│       ├── proof/                   # 2B proof files
│       └── docs/                    # 2b_cache_explanation, haiku, Be A Man paragraphs
├── SEIR files/LAB2/                 # Lab specs (2a_lab.txt, 2b_*.txt, etc.)
├── capture_all_proofs.sh
└── run_all_gates_commands.sh
```

### 7.2 Where to look when reviewing

1. **Names and wiring:** This report (§3–5) plus `Lab2A/*.tf` and `Lab2A/variables.tf`, `data.tf`, `providers.tf`.
2. **Behavior order and policies:** `lab2_cloudfront_alb.tf` (behaviors) and `lab2b_cache_policies.tf`, `lab2b_response_headers_policy.tf`, `lab2b_honors_origin_driven.tf`.
3. **Proof and status:** `deliverables/docs/GRADER_START_HERE.md` → `DELIVERABLES_INDEX.md` and `FINAL_SUBMISSION_MAP.md`; actual files under `Lab2A/deliverables/proof/` and `Lab2B/deliverables/proof/`.
4. **Gaps and remaining work:** `deliverables/docs/REMAINING_GAPS_CHECKLIST.md` and `LAB2_REMAINING_WORK_REPORT.md`.

### 7.3 Why this structure

- **Single CloudFront stack:** 2A and 2B share one distribution, so one Terraform dir (`Lab2A`) keeps all CF and ALB-related resources together.
- **Deliverables hub:** One place (`Lab2/deliverables/docs/`) for indexes and checklists; proof stays in Lab2A/Lab2B to avoid duplication and keep 2A vs 2B evidence clear.
- **Lab2B without Terraform dir:** 2B is implemented in Lab2A Terraform + Lab1 app; Lab2B folder holds only proof and written docs.

---

## 8. Quick review checklist

Use this to validate the lab end-to-end:

- [ ] **Variables:** `project` / `domain_name` / `origin_secret` match intent; ACM and zone exist for `domain_name`.
- [ ] **Data sources:** All referenced resources (ALB, SG, listener, TG, zone, cert) exist and names match `var.project` and `var.domain_name`.
- [ ] **Behavior order:** `/api/public-feed` before `/api/*`; `/api/*` before default.
- [ ] **Origin:** ALB as origin, http-only, custom header X-Chewbacca-Growl set from `var.origin_secret`.
- [ ] **Origin cloaking:** SG rule from CloudFront prefix list only; listener rule forwards only when header matches.
- [ ] **WAF:** CLOUDFRONT scope, us-east-1; attached to distribution.
- [ ] **DNS:** A (alias) apex and app to CloudFront; no public A to ALB.
- [ ] **Static cache:** Path-only cache key; RHP adds Cache-Control; ORP minimal.
- [ ] **API cache:** TTL 0 for /api/*; ORP forwards cookies/whitelist headers/all QS.
- [ ] **Public-feed:** UseOriginCacheControlHeaders; app sends Cache-Control public, s-maxage=30.
- [ ] **App routes:** /api/list (private, no-store), /api/public-feed (public, s-maxage=30), /static/example.txt (ETag, Last-Modified).
- [ ] **Proof paths:** Match DELIVERABLES_INDEX and FINAL_SUBMISSION_MAP; no invented proof.

---

*End of Lab 2 Full Review Report. For submission status and gaps, use DELIVERABLES_INDEX.md and REMAINING_GAPS_CHECKLIST.md.*
