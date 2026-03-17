# Lab 3 — Full Context

Use this when you need to understand the whole lab quickly. All the important IDs, decisions, and architecture in one place.

---

## What this lab is

A multi-region AWS setup for a Japanese medical company. The law (APPI) says patient records have to stay in Japan. The architecture enforces that: Tokyo has the only database, São Paulo and Osaka are compute-only regions that reach back to Tokyo over Transit Gateway.

- **AWS account:** 583001104385
- **Domain:** chewbacca-growls.com (lab context), lab3.cloudyjones.xyz (Route 53, live)
- **Terraform state:** split — Tokyo, São Paulo, and Osaka are independent roots. Apply Tokyo first, then São Paulo, then Osaka.

---

## Regions

**Tokyo (ap-northeast-1)** — VPC 10.0.0.0/16, RDS MySQL, EC2 Flask app, ALB, Transit Gateway, CloudFront, two WAFs (one edge scope, one ALB regional scope)

**São Paulo (sa-east-1)** — VPC 10.1.0.0/16, EC2 Flask app, ALB, Transit Gateway, no database

**Osaka (ap-northeast-3)** — VPC 10.2.0.0/16, EC2 Flask app, ALB, Transit Gateway, no database, Route 53 failover secondary

---

## Traffic path

```
User
  → CloudFront (d1ukfjlu61n1r6.cloudfront.net)
  → WAF CLOUDFRONT scope (lab3-waf-acl, us-east-1) — blocks OWASP Top 10, bad IPs
  → Tokyo ALB (adds x-cloudfront-secret header: "Sao Paulo living tokyo dreaming")
  → WAF REGIONAL (lab3-alb-waf, ap-northeast-1) — blocks anything without that header
  → EC2 Flask app (port 5000)
  → RDS MySQL (lab3-tokyo-mysql)
```

Direct hits to the ALB DNS are blocked by the regional WAF. Only CloudFront-originated requests have the secret header and get through.

---

## Key resource IDs

| Resource | ID / Value |
|---|---|
| CloudFront distribution | E21VKJX8IT4I09 |
| CloudFront domain | d1ukfjlu61n1r6.cloudfront.net |
| WAF (CloudFront scope) | 9a2f2c08-c9bb-45f8-9905-0027fe139d66 |
| WAF (ALB regional) | lab3-alb-waf (REGIONAL, ap-northeast-1) |
| Tokyo VPC | vpc-0686276a78477bd46 |
| Tokyo EC2 | i-0dde4915a773fa365 |
| Tokyo ALB | lab3-tokyo-alb-2005384345.ap-northeast-1.elb.amazonaws.com |
| Tokyo RDS | lab3-tokyo-mysql.clyg202mw62j.ap-northeast-1.rds.amazonaws.com |
| Tokyo TGW | tgw-07c760214412bf700 |
| São Paulo TGW | tgw-0ba2e4a991b66f7b0 |
| TGW peering (SP) | tgw-attach-069c3589989778681 |
| TGW peering (Osaka) | tgw-attach-0ab9a7e2ac5e244bd |
| Route 53 hosted zone | Z01825573SNDEWHMXEY94 |
| São Paulo EC2 | i-069c5269912fccabd |
| Osaka EC2 | i-01ad3bc1822996657 |

---

## Tokyo Terraform files (quick reference)

- `provider.tf` — two providers: default (ap-northeast-1) and alias `useast1` (us-east-1) for CloudFront and CLOUDFRONT-scope WAF
- `main.tf` — VPC, subnets, IGW, NAT, route tables
- `sg.tf` — security groups for ALB, EC2, RDS
- `rds.tf` — MySQL RDS (encrypted, private)
- `ec2_app.tf` — EC2 instance, IAM role, ALB, target group
- `cloudfront.tf` — CloudFront distribution, origin = Tokyo ALB, CachingDisabled, secret header
- `waf.tf` — CloudFront-scope WAF (managed rules) + REGIONAL WAF on ALB (secret header rule) + association
- `tgw.tf` — TGW, VPC attachment, peering to SP, accepter for Osaka
- `routes.tf` — private route table entries to SP and Osaka via TGW
- `outputs.tf` — exports VPC, subnet, RDS, ALB, TGW, CloudFront, WAF values

---

## What's live vs not

Everything in the truth table is deployed. The one thing that wasn't fully verified after last deploy: `/db-check` endpoint on Tokyo EC2 — needs a fresh curl after resuming.

Route 53 records are live but DNS was still propagating through Namecheap as of 2026-03-16.

---

## Rules that don't change

- Only Tokyo has RDS. Never add a database to São Paulo or Osaka.
- The `RequireCloudFrontSecret` WAF rule lives on the **REGIONAL** (ALB) WAF, not the CLOUDFRONT-scope WAF. The viewer never sends the secret — CloudFront adds it when calling the origin.
- CloudFront has CachingDisabled for all paths. No PHI at the edge.
- Apply order: Tokyo → São Paulo → Osaka. São Paulo reads Tokyo's remote state.
- AWS description fields are ASCII only (no em dashes, special chars) — WAF had a deploy failure from this.
