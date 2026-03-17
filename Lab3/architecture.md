# Lab 3 — Architecture Notes

**Date:** 2026-03-15

---

## The one rule that drives everything

PHI (patient records) stays in Tokyo. São Paulo and Osaka run the app but have no database.

---

## Region breakdown

| Region | Role | Has DB? | PHI at rest? |
|---|---|---|---|
| Tokyo (ap-northeast-1) | Data authority | Yes | Yes (only here) |
| São Paulo (sa-east-1) | Stateless compute | No | No |
| Osaka (ap-northeast-3) | Japan-side failover | No | No |

---

## Network

- Tokyo VPC: 10.0.0.0/16
- São Paulo VPC: 10.1.0.0/16
- Osaka VPC: 10.2.0.0/16

Each region has its own Transit Gateway. The TGWs are connected via peering:
- Tokyo ↔ São Paulo: peering available
- Tokyo ↔ Osaka: peering available

Private route tables send cross-region traffic through the local TGW. Traffic never hits the public internet.

---

## How a request works

1. Request comes in through CloudFront
2. CloudFront passes it to the Tokyo ALB with a secret header
3. The ALB-level WAF blocks anything without that header (so direct ALB hits are blocked)
4. EC2 Flask app handles the request
5. If it needs the database, it connects to Tokyo RDS over private networking
6. Response goes back the same path

São Paulo and Osaka apps work the same way except their DB calls travel over the TGW corridor to Tokyo first.

---

## Security group chain (Tokyo)

- **ALB SG:** accepts 80/443 from anywhere (CloudFront), sends to EC2 on port 5000
- **EC2 SG:** accepts port 5000 from ALB only, sends to RDS on 3306
- **RDS SG:** accepts 3306 from Tokyo EC2, São Paulo CIDR, Osaka CIDR — nothing else

---

## Edge layer

CloudFront sits in front of everything. WAF runs at two points:
- At the CloudFront edge: blocks OWASP Top 10 attacks and known bad IPs
- On the ALB: blocks anything that didn't come through CloudFront (missing secret header)

Both are live as of March 2026.

---

## Route 53

Failover setup pointing `lab3.cloudyjones.xyz` at Tokyo ALB as primary, Osaka ALB as secondary. If Tokyo's health check fails, traffic moves to Osaka. The database stays in Tokyo either way.
