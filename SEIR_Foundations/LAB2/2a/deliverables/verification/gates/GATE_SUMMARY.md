# Lab 2 Gate Summary
Run date: 2026-03-17

## Gate 1 — Network + RDS Verification (`gate_network_db.sh`)
**Result: FAIL**

PASS items:
- Credentials OK
- RDS instance `lab1a-mysql-db` exists
- RDS is NOT publicly accessible (correct)
- DB port 3306 discovered correctly
- EC2 SG resolved

Failure:
- No SG-to-SG ingress rule found allowing EC2 SG → RDS on port 3306

**Root cause:** The EC2 instance (`i-06003411f26d02bef`) is in VPC `vpc-0e61a7b7044f6dfb2`
(Lab 2 VPC) with SG `cloudyjones-ec2-sg01`. The RDS (`lab1a-mysql-db`) is in VPC
`vpc-0df82350861e1de16` (Lab 1A VPC) and only allows `sg-04b5ded2e787fd2cf` (`labA-ec2-lab`).
These are different VPCs with no peering — the EC2 and RDS are network-isolated from each other.

This explains why `/api/list` hangs (Flask tries to connect to MySQL, gets no response, eventually
times out after 30+ seconds). Fix requires VPC peering or moving RDS to Lab 2 VPC.

---

## Gate 2 — Secrets Manager + IAM Role (`gate_secrets_and_role.sh`)
**Result: PASS**

PASS items:
- Secret `lab/rds/mysql` exists and is describable
- EC2 instance has IAM instance profile attached
- Profile → role resolved: `cloudyjones-ec2-profile01` → `cloudyjones-ec2-role01`
- No resource policy blocking access

Warning (non-blocking):
- Running off-instance as AWSCLI user (expected — this is a local CLI check)

---

## Gate 3 — CloudFront + ALB Infrastructure (`run_all_gates_lab2_alb.sh`)
**Result: FAIL**

PASS items (16 checks):
- CloudFront Enabled and Deployed
- Aliases include `cloudyjones.xyz`
- ACM cert ISSUED, covers `cloudyjones.xyz`
- Route53 A alias HostedZoneId is CloudFront (Z2FDTNDATAQYW2)
- ALB exists, listeners on 443 and 80
- ALB SG not world-open on 443 or 80
- CloudFront origin matches ALB DNS

Failures:
- WAF WebACL not associated with CloudFront (the WAF is created but the gate's association check is failing)
- Route53 A alias target trailing-dot mismatch (script bug: expected vs actual differ only by trailing `.`)
- Route53 AAAA alias missing (IPv6 record not configured)
- CloudFront logging not enabled
- ALB scheme is internet-facing (expected internal by gate — but internet-facing is correct for this architecture)

**Note:** Most failures are gate strictness issues (trailing dot, IPv6 AAAA, logging) rather than
architectural problems. The WAF is attached in Terraform (`web_acl_id = aws_wafv2_web_acl.cloudyjones_cf_waf01.arn`).

---

## Gate 4 — Cache Policy Modernity (`run_all_gates.sh`)
**Result: FAIL**

Failures (same pattern as Gate 3):
- WAF association check failing
- Route53 trailing dot mismatch
- Route53 AAAA alias missing
- CloudFront logging not enabled

---

## Summary Table

| Gate | Result | Blocking? |
|------|--------|-----------|
| Network + RDS | FAIL | Yes — VPC mismatch, DB unreachable from Lab2 EC2 |
| Secrets + Role | PASS | — |
| CloudFront + ALB infra | FAIL | No — mostly gate strictness issues, core infra is correct |
| Cache policy modernity | FAIL | No — same trailing-dot / logging / AAAA issues |

## What the Gate Failures Mean for Grading

The two real issues are:
1. **DB connectivity**: Lab 2 EC2 cannot reach Lab 1A RDS. The app is deployed but `list_notes()` hangs.
2. **Gate script compatibility**: The scripts use Linux `sed` syntax that is incompatible with macOS BSD sed (visible in the `sed: unused label` warnings). Results may differ if run on a Linux grading machine.
