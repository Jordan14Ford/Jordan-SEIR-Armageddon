# Lab 3 — Japan Medical

**Owner:** Jordan Ford  
**Last updated:** March 2026

---

## What this is

A real multi-region AWS architecture built for a healthcare scenario. The rule that drives everything: **patient data has to stay in Japan.** That's not a preference — it's the law (APPI). So the whole design is built around keeping the database in Tokyo while still letting doctors in other countries use the app.

Think of Tokyo as the vault. São Paulo and Osaka can open the drawer but they can't take anything home.

---

## What's built

| Piece | Status |
|---|---|
| Tokyo VPC + RDS + EC2 + ALB | Live |
| São Paulo VPC + EC2 + ALB (no DB) | Live |
| Osaka VPC + EC2 + ALB (no DB, Japan failover) | Live |
| Transit Gateway corridor (Tokyo ↔ São Paulo ↔ Osaka) | Live |
| CloudFront distribution — `E21VKJX8IT4I09` | Live |
| WAF (edge + ALB) | Live |
| Route 53 failover — `lab3.cloudyjones.xyz` | Live (DNS propagating) |

---

## How the regions work

**Tokyo (`ap-northeast-1`)** — the only region with a database. All patient data lives here. If Tokyo goes down, the app degrades but nothing leaks.

**São Paulo (`sa-east-1`)** — runs the app only. No database. When a doctor in Brazil writes a record, that data crosses the TGW corridor and lands in Tokyo. São Paulo never holds it.

**Osaka (`ap-northeast-3`)** — same deal as São Paulo but in Japan, so it's the failover. If Tokyo's app tier goes down, Route 53 flips traffic to Osaka. The database stays in Tokyo either way.

---

## How traffic flows

```
User → CloudFront → WAF (edge) → Tokyo ALB → WAF (ALB) → EC2 Flask → Tokyo RDS
```

CloudFront adds a secret header before hitting the ALB. The ALB-level WAF blocks anything that doesn't have that header — so direct hits to the ALB are blocked. Only CloudFront traffic gets through.

---

## Repo layout

```
Lab3/
├── tokyo/          VPC, EC2, ALB, RDS, CloudFront, WAF, TGW
├── sao-paulo/      VPC, EC2, ALB, TGW (no RDS)
├── osaka/          VPC, EC2, ALB, TGW (no RDS)
├── route53/        Failover DNS
├── audit-pack/     Evidence files for submission
├── python/         Scripts that generate audit evidence
└── notes/          Working notes, pause/resume runbook
```

---

## Audit evidence

The `audit-pack/` folder has everything you'd need to prove compliance:

- `01` — CLI proof RDS only exists in Tokyo
- `02` — CloudFront live evidence
- `03` — WAF live evidence
- `04` — CloudTrail change log
- `05` — TGW corridor + route table proof
- `06` — Plain-language summary for a reviewer

---

## Cost / pause notes

Resources were stopped overnight to save money. Before treating anything as "currently live," check `notes/paused_resources_2026-03-14.md` for the restart runbook. NAT gateways were deleted and recreated — if you pause again, private route tables need to be updated with the new NAT IDs.

---

## The one thing that can't change

Tokyo is the only place PHI gets stored. Every other decision in this lab is flexible. That one isn't.
