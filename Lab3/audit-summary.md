# Lab 3 — Verification Notes

**Date:** 2026-03-15  
**State at time of check:** Paused (EC2/RDS stopped, NAT gateways deleted for cost savings)

---

## Database check

- Tokyo has one RDS instance: `lab3-tokyo-mysql`. Stopped at time of check (intentional). Not publicly accessible. Storage encrypted. No read replicas.
- São Paulo: no RDS. Zero results on describe-db-instances.
- Osaka: no RDS. Zero results.

PHI is only in Tokyo. That's the point.

---

## Transit Gateway

- Tokyo TGW: `tgw-07c760214412bf700` (available, ASN 64512)
- São Paulo TGW: `tgw-0ba2e4a991b66f7b0` (available, ASN 64513)
- Osaka TGW: `tgw-0f398231e117b7e30` (available, ASN 64514)
- All peering attachments in available state.

---

## Route tables

Tokyo private RT has routes to Osaka (10.2.0.0/16 → TGW) and 0.0.0.0/0 → NAT. The São Paulo return route (10.1.0.0/16) was missing from the live table at time of check — it's in Terraform but wasn't applied yet. Run `terraform apply` in `tokyo/` after resuming to fix it.

São Paulo: has 10.0.0.0/16 → São Paulo TGW. Good.

Osaka: needs to be checked after resume.

NAT gateways are deleted — all private 0.0.0.0/0 routes are blackholes until they're recreated.

---

## RDS security group

- Port 3306 open from: Tokyo EC2 SG, 10.1.0.0/16 (São Paulo), 10.2.0.0/16 (Osaka).
- No 0.0.0.0/0 on 3306. Good.

---

## App connectivity

Not tested — environment was paused. When it comes back up, test with:

```bash
nc -vz lab3-tokyo-mysql.clyg202mw62j.ap-northeast-1.rds.amazonaws.com 3306
```

Previously the São Paulo app returned `db_host` pointing at Tokyo RDS, confirming the corridor works.

---

## What needs re-checking after resume

1. Recreate NAT gateways, update private route table 0.0.0.0/0 targets
2. Run `terraform apply` in `tokyo/` — picks up any missing routes
3. Restart EC2 instances and RDS
4. Re-run connectivity test from São Paulo EC2
5. Re-run curl on health endpoints to confirm app is up

See `notes/paused_resources_2026-03-14.md` for the full restart runbook.
