# Session Summary - March 13, 2026

## Overview

This session covered AWS cost management for Labs 1/2, code authenticity improvements for Lab 3, and fixing the critical TGW routing gap.

---

## Part 1: AWS Cost Pause (Labs 1 & 2)

### Resources Stopped (us-east-1 + us-east-2)

| Resource | Region | Action | Savings |
|----------|--------|--------|---------|
| EC2: Lab1A-EC2-Proper | us-east-1 | stopped | ~$7/mo |
| EC2: cloudyjones-ec2-private01 | us-east-1 | stopped | ~$7/mo |
| EC2: lab-ec2-app-fixed-v2 | us-east-2 | stopped | ~$7/mo |
| RDS: lab1a-mysql-db | us-east-1 | stopped | ~$15/mo |
| RDS: lab-mysql | us-east-2 | stopped | ~$15/mo |
| NAT Gateway: cloudyjones-nat-gw | us-east-1 | **deleted** | ~$32/mo |
| NAT Gateway: (unnamed) | us-east-2 | **deleted** | ~$32/mo |

**Total savings: ~$115/month**

### Documentation Created

- `Lab3/notes/deleted_nat_gateways.md` - Full details of deleted NAT Gateways with recreation commands

### Still Running (not addressed)

- ALB: cloudyjones-alb01 (us-east-1) - ~$16/mo
- RDS: lab1c-mysql (us-east-2, broken state) - ~$15/mo

---

## Part 2: Lab 3 Architecture Review

### North Star Goal

Build a HIPAA/APPI-compliant multi-region AWS architecture where:
- **PHI at rest only in Tokyo** (ap-northeast-1)
- **São Paulo is compute-only** (sa-east-1) - connects to Tokyo RDS via TGW

### Architecture

```
Tokyo (ap-northeast-1)              São Paulo (sa-east-1)
VPC: 10.0.0.0/16                    VPC: 10.1.0.0/16
├── ALB (public)                    ├── ALB (public)
├── EC2 (private)                   ├── EC2 (private)
├── RDS MySQL (private)             └── TGW attachment
└── TGW attachment                       │
     │                                   │
     └─────── TGW Peering ───────────────┘
```

### Key Resources Deployed

- Tokyo: VPC, EC2, RDS, ALB, TGW, NAT Gateway
- São Paulo: VPC, EC2, ALB, TGW, NAT Gateway (no RDS)
- TGW Peering: Tokyo initiates, São Paulo accepts
- BGP ASNs: Tokyo 64512, São Paulo 64513

---

## Part 3: Code Authenticity Improvements

### Problem

The Terraform code had obvious AI-generated patterns:
- Uniform header blocks on every file
- Embedded troubleshooting guides
- Paragraph-length variable descriptions
- "KEY DECISIONS" and "APPI COMPLIANCE" lectures

### Files Simplified

**Tokyo:**
- variables.tf - descriptions shortened to one-liners
- main.tf - headers removed, brief comments
- sg.tf - removed traffic flow diagrams
- rds.tf - removed APPI lecture, added `# multi_az = true # would double cost`
- ec2_app.tf - added `# TODO: switch to systemd`
- tgw.tf - removed peering lecture
- routes.tf - now 6 lines

**São Paulo:**
- main.tf - added `# mostly copied from tokyo`
- ec2_app.tf - removed architecture diagrams
- tgw.tf - simplified

### Files Deleted

- `notes/decisions_review.md` - 478-line architectural review (too polished)

### Created

- `notes/authenticity_checklist.md` - what's done vs what still needs personal touches

### Still Need Attention

- sao-paulo/variables.tf - still has verbose descriptions
- sao-paulo/routes.tf - still has AI header
- */outputs.tf files - may be verbose

---

## Part 4: TGW Route Fix (Critical)

### Problem Identified

The Terraform code for routes was correct, but **routes were never applied to AWS**.

**Before:**
| Route Table | Routes |
|-------------|--------|
| Tokyo private | local, NAT | ❌ Missing `10.1.0.0/16 → TGW` |
| São Paulo private | local, NAT | ❌ Missing `10.0.0.0/16 → TGW` |

Without these routes, TGW corridor existed but packets couldn't reach it.

### Fix Applied

```bash
cd Lab3/tokyo && terraform apply -target=aws_route.tokyo_to_sao_paulo
cd Lab3/sao-paulo && terraform apply -target=aws_route.sao_paulo_to_tokyo
```

**After:**
| Route Table | Destination | Target |
|-------------|-------------|--------|
| Tokyo private | 10.0.0.0/16 | local |
| Tokyo private | **10.1.0.0/16** | **tgw-07c760214412bf700** ✅ |
| Tokyo private | 0.0.0.0/0 | NAT |
| São Paulo private | **10.0.0.0/16** | **tgw-0ba2e4a991b66f7b0** ✅ |
| São Paulo private | 10.1.0.0/16 | local |
| São Paulo private | 0.0.0.0/0 | NAT |

### Verification

```bash
curl http://lab3-sao-paulo-alb-732953206.sa-east-1.elb.amazonaws.com/
# {"db_host":"lab3-tokyo-mysql.clyg202mw62j.ap-northeast-1.rds.amazonaws.com","message":"Sao Paulo Flask App","note":"This app connects to Tokyo RDS over TGW"}

curl http://lab3-sao-paulo-alb-732953206.sa-east-1.elb.amazonaws.com/health
# {"hostname":"ip-10-1-10-16.sa-east-1.compute.internal","region":"sa-east-1","status":"healthy"}
```

---

## Part 5: Lab 3 Resources Started

Started these for testing:

| Resource | ID | Status |
|----------|-----|--------|
| Tokyo RDS | lab3-tokyo-mysql | available |
| Tokyo EC2 | i-0dde4915a773fa365 | running (10.0.10.118) |
| São Paulo EC2 | i-069c5269912fccabd | running (10.1.10.16) |

### Endpoints

- Tokyo RDS: `lab3-tokyo-mysql.clyg202mw62j.ap-northeast-1.rds.amazonaws.com`
- Tokyo ALB: `lab3-tokyo-alb-2005384345.ap-northeast-1.elb.amazonaws.com`
- São Paulo ALB: `lab3-sao-paulo-alb-732953206.sa-east-1.elb.amazonaws.com`

---

## Current State Summary

### What's Running (Costing Money)

| Resource | Region | Est. Cost |
|----------|--------|-----------|
| Tokyo RDS | ap-northeast-1 | ~$15/mo |
| Tokyo EC2 | ap-northeast-1 | ~$7/mo |
| Tokyo NAT | ap-northeast-1 | ~$32/mo |
| Tokyo ALB | ap-northeast-1 | ~$16/mo |
| São Paulo EC2 | sa-east-1 | ~$7/mo |
| São Paulo NAT | sa-east-1 | ~$32/mo |
| São Paulo ALB | sa-east-1 | ~$16/mo |
| **Lab 3 Total** | | **~$125/mo** |

### What's Stopped

- Labs 1/2 EC2 instances (3)
- Labs 1/2 RDS instances (2)
- Labs 1/2 NAT Gateways deleted (documented for recreation)

### What's Proven

- ✅ Tokyo RDS exists only in ap-northeast-1
- ✅ São Paulo has no RDS
- ✅ TGW peering is active
- ✅ Private route tables have TGW routes
- ✅ São Paulo app can resolve Tokyo RDS endpoint
- ⏳ Actual DB connectivity test (need /db-check endpoint or SSM test)

---

## Next Steps

1. **Test actual DB connectivity** - SSM into São Paulo EC2, run `mysql -h <tokyo-rds-endpoint>`
2. **Build audit-pack** - Now that routing is proven
3. **Add CloudFront + WAF** (Phase 6)
4. **Clean up remaining AI patterns** in sao-paulo/variables.tf, routes.tf, outputs.tf
5. **Stop Lab 3 resources** when done to save costs

---

## Key Files Modified This Session

```
Lab3/
├── notes/
│   ├── deleted_nat_gateways.md (created)
│   ├── authenticity_checklist.md (created)
│   ├── session_summary_2026-03-13.md (this file)
│   └── decisions_review.md (deleted)
├── tokyo/
│   ├── variables.tf (simplified)
│   ├── main.tf (simplified)
│   ├── sg.tf (simplified)
│   ├── rds.tf (simplified)
│   ├── ec2_app.tf (simplified)
│   ├── tgw.tf (simplified)
│   └── routes.tf (simplified, APPLIED)
└── sao-paulo/
    ├── main.tf (simplified)
    ├── ec2_app.tf (simplified)
    ├── tgw.tf (simplified)
    └── routes.tf (APPLIED)
```

---

## AMI IDs Verified

- Tokyo (ap-northeast-1): `ami-0599b6e53ca798bb2` - Amazon Linux 2023
- São Paulo (sa-east-1): `ami-0b636fa791bb0970c` - Amazon Linux 2023, valid until 2026-06-01
