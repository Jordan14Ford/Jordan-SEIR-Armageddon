# Auditor Narrative

**Lab 3 — Multi-Region Data Residency**  
**Regions:** Tokyo (ap-northeast-1), São Paulo (sa-east-1), Osaka (ap-northeast-3)  
**Date:** March 2026

---

The goal of this architecture was to let a Japanese medical organization serve users globally while keeping all patient records physically stored in Japan. Japan's APPI law requires it, and this design enforces it at the infrastructure level — not just in policy.

Here's how it works in plain terms: the database lives in Tokyo and only in Tokyo. São Paulo and Osaka run the application but have no local database. When someone in Brazil opens the app and accesses a patient record, that request travels over a private AWS network path (Transit Gateway) to Tokyo, pulls the data, and sends it back. The data never gets written to anything in Brazil. Same story for Osaka.

This isn't just a design choice — it's provable. The CLI output in `01_data-residency-proof.txt` shows RDS exists in Tokyo and returns zero results in São Paulo. The TGW attachments and private route tables in `05_network-corridor-proof.txt` show the corridor is active and traffic is routed correctly.

On top of that, CloudFront sits in front of the whole system as the only public entry point. WAF runs at the CloudFront edge (OWASP Top 10 + known bad IPs) and on the ALB (blocks anything that didn't come through CloudFront). So even if someone found the ALB's DNS and tried to hit it directly, they'd get blocked. CloudFront live evidence is in `02_edge-proof-cloudfront.txt` and WAF evidence is in `03_waf-proof.txt`.

Infrastructure changes are logged in CloudTrail. `04_cloudtrail-change-proof.txt` has a sample of recent events showing who changed what and when.

The main tradeoff in this design is latency. A doctor in São Paulo connecting to Tokyo RDS is slower than if there was a local database. We made that call deliberately — slower is better than illegal. For a healthcare system under APPI, there's no other option.

| Claim | Evidence file |
|---|---|
| RDS exists only in Tokyo | `01_data-residency-proof.txt` |
| No RDS in São Paulo | `01_data-residency-proof.txt` |
| TGW corridor connects regions | `05_network-corridor-proof.txt` |
| Route tables use TGW for cross-region traffic | `05_network-corridor-proof.txt` |
| RDS SG allows São Paulo and Osaka CIDRs | `05_network-corridor-proof.txt` |
| CloudFront deployed and active | `02_edge-proof-cloudfront.txt` |
| WAF deployed and attached | `03_waf-proof.txt` |
| Infrastructure changes are logged | `04_cloudtrail-change-proof.txt` |
