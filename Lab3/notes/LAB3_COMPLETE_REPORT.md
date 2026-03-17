# Lab 3 Notes

Working notes on what was built and what's where. For the actual submission docs, see `audit-pack/` and `README.md`.

---

## What the lab is

Multi-region AWS architecture for a Japanese medical company. APPI requires patient records to stay in Japan. Tokyo has the only database. São Paulo and Osaka are compute-only and connect to Tokyo RDS over Transit Gateway.

## What's built

- **Tokyo** — VPC, EC2 (Flask), ALB, RDS MySQL, TGW, CloudFront, two WAFs
- **São Paulo** — VPC, EC2 (Flask), ALB, TGW (no DB)
- **Osaka** — VPC, EC2 (Flask), ALB, TGW (no DB, Japan-side failover)
- **Route 53** — failover between Tokyo and Osaka ALBs at `lab3.cloudyjones.xyz`

CIDRs: Tokyo 10.0.0.0/16, São Paulo 10.1.0.0/16, Osaka 10.2.0.0/16

## What's still not fully clean

- Osaka EC2 had a user_data issue on first launch. App was started manually via SSM. Terraform is fixed but the instance hasn't been re-verified.
- Tokyo return route to São Paulo was missing from the live route table at one point during the cost pause. Should come back after `terraform apply` in Tokyo.
- Route 53 DNS propagation through Namecheap was still in progress as of 2026-03-16.
- Egress rules on São Paulo and Osaka are permissive (0.0.0.0/0 outbound).

## Where things live

- Architecture decisions → `DECISIONS.md`
- Audit evidence → `audit-pack/`
- Pause/resume runbook → `notes/paused_resources_2026-03-14.md`
- Terraform reference → `tokyo/docs/lab3_report.md`
- Full resource IDs → `FULL_CONTEXT_FOR_AI.md`
