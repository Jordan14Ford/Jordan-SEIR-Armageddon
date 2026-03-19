# Lab 2 — Proof Files (Canonical Locations)

Proof files are **not duplicated** here. Use these paths when verifying or submitting.

## Lab 2A proof (infrastructure)

**Path:** `Lab2/Lab2A/deliverables/proof/`

| File | What it proves |
|------|----------------|
| `proof1-cf-apex-200.txt` | HTTP 200 from apex domain via CloudFront |
| `proof2-cf-app-200.txt` | HTTP 200 from app subdomain via CloudFront |
| `proof3-dig-cloudfront-ips.txt` | DNS resolves to CloudFront IPs |
| `proof4-cf-config.json` | CloudFront distribution config |
| `proof5-waf-cloudfront-scope.json` | WAF WebACL in CLOUDFRONT scope |
| `alb_direct_blocked.txt` | Direct ALB access fails (origin cloaking) |
| `dig_cf_proof.txt` | CNAME/alias to CloudFront |

## Lab 2B proof (caching)

**Path:** `Lab2/Lab2B/deliverables/proof/`

| File | What it proves |
|------|----------------|
| `proof-static-example-1.txt` | First request to /static/example.txt (Hit, Age) |
| `proof-static-example-2.txt` | Second request — same object, Age increases |
| `proof-static-qs-v1.txt` | /static/example.txt?v=1 — cache key ignores QS |
| `proof-static-qs-v2.txt` | /static/example.txt?v=2 — same cached object |
| `proof-api-list-1.txt` | /api/list — x-cache: Error, Cache-Control: private, no-store |
| `proof-api-list-2.txt` | Second /api/list — no caching |
| `proof-public-feed-miss.txt` | /api/public-feed — Miss, origin Cache-Control |
| `proof-public-feed-hit.txt` | /api/public-feed — Hit, Age (ManA sequence) |
| `proof-invalidation-before.txt` | Static Hit before invalidation (ManB) |
| `proof-invalidation-after.txt` | Static Miss after invalidation (ManB) |
| `proof-invalidation-record.json` | create-invalidation completed (/static/index.html) |
| `proof-invalidation-example-record.json` | Invalidation for /static/example.txt |
| `proof-manc-miss.txt` | /static/example.txt — Miss with ETag, Last-Modified |
| `proof-manc-hit.txt` | Hit with ETag in response |
| `proof-manc-304.txt` | 304 Not Modified — conditional request (ManC) |
| `proof-manc-refreshhit.txt` | *(Note: file shows Hit; literal RefreshHit requires short TTL)* |

See **docs/DELIVERABLES_INDEX.md** for status (ready / partial / pending) of each.
