# Architecture Summary

This is a cross-region AWS setup built around one constraint: patient data for a Japanese medical organization has to stay in Japan. Japan's APPI law requires it. The architecture is designed so that rule is enforced at the infrastructure level, not just on paper.

## The core idea

Tokyo holds the database. Every other region is just compute. Doctors in São Paulo or anywhere else can use the app, but when they read or write patient records, that data lives in Tokyo and only Tokyo.

## How the regions are split

**Tokyo (`ap-northeast-1`)** — the only region with a database (MySQL RDS). Runs the primary app tier, hosts the Transit Gateway hub, and is the CloudFront origin. All PHI at rest is here.

**São Paulo (`sa-east-1`)** — runs the app with no local database. When a user there accesses patient records, the request travels over the Transit Gateway corridor to Tokyo RDS, then the response comes back.

**Osaka (`ap-northeast-3`)** — same as São Paulo but inside Japan, used as a failover region. If Tokyo's app tier goes down, Route 53 sends traffic to Osaka. The database still stays in Tokyo.

## How the regions connect

Each region has its own Transit Gateway. The three TGWs are connected via peering attachments. Private route tables in each region route cross-region traffic through those TGWs — it never touches the public internet. The Tokyo RDS security group only allows MySQL access from the Tokyo app subnets, the São Paulo CIDR, and the Osaka CIDR.

## The edge layer

CloudFront sits in front of everything. There's one public entry point, one origin (Tokyo ALB), and WAF running at the edge. CloudFront adds a secret header before hitting the ALB, and a second WAF on the ALB blocks any request missing that header. Direct ALB access is blocked.

## The tradeoff

São Paulo users experience a bit more latency because every DB call goes to Japan. That's intentional. The alternative — copying data to São Paulo — would break the residency requirement. Slightly slower is the right call here.
