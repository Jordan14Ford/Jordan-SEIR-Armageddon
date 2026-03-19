# DECISIONS.md — Why things are built the way they are

These are the main choices I made in this lab and why. Not all of them were obvious up front.

---

**Tokyo is the only region with a database.**

Japan's privacy law (APPI) says patient data for Japanese residents has to stay in Japan. The cleanest way to prove that is to put the database in one place and never replicate it. Tokyo is that place. São Paulo and Osaka connect to it over the Transit Gateway — they don't hold any data themselves. If an auditor asks "where does PHI live," the answer is one region, one RDS instance, easy to verify with a single CLI command.

I considered adding a read replica in São Paulo to cut latency. Rejected it. A replica is still data at rest outside Japan.

---

**Osaka for Japan-side failover, not Sydney.**

If the Tokyo app tier goes down, traffic fails over to Osaka. Both are in Japan, so the compliance picture doesn't change — the database is still in Tokyo and the failover compute is still inside Japanese borders. Using Sydney or another non-Japan region would have muddied that.

---

**Transit Gateway instead of VPC peering.**

Three regions means at least three connections. With VPC peering you'd have three separate peering links, each with its own route table entries and nothing tying them together. TGW acts like a hub — each region attaches once, and routing is managed centrally. More importantly for this lab, a TGW creates a visible controlled corridor that's easy to describe to an auditor. "Here's the route, here's the attachment, here's the SG rule that allows it" — that's a clean story.

I could have used VPN over the internet. I didn't because TGW keeps the traffic on the AWS backbone and there's no public exposure of the DB path.

---

**São Paulo has no database at all.**

No read replica, no local cache, nothing. Every DB query from São Paulo crosses the TGW to Tokyo. The latency hit (~200ms) is real and I accepted it. The alternative — storing PHI locally in São Paulo — would break the compliance model. Faster is not worth illegal.

---

**Flask runs under systemd, not nohup.**

`nohup` doesn't restart the app if it crashes and doesn't survive a reboot. `systemd` does both. For a lab where instances get stopped and restarted regularly, this matters. Using `nohup` would mean manually restarting Flask every time an instance comes back up, which would make the health checks fail and make the whole thing look broken.

---

**The Tokyo EC2 role only has Secrets Manager read access.**

The Flask app needs the DB credentials at startup — username, password, database name. It reads them from Secrets Manager and that's it. There's no reason for the instance to write or modify secrets, so I didn't give it that permission. Least privilege: if the instance gets compromised, an attacker can read the secret but can't rotate, delete, or create new ones.

---

**One EC2 instance per region, no Auto Scaling.**

This is a compliance and architecture demo, not a production workload. ASGs would add launch templates, scaling policies, and complexity that doesn't add anything to what the lab is trying to prove. A single instance per region is enough to demonstrate the regional roles and the data flow.

---

**Tokyo ALB is the only CloudFront origin.**

I thought about adding São Paulo as a second origin so South American users would get lower latency from CloudFront. Decided against it. The whole point of this architecture is that Tokyo is the data authority. Making São Paulo an origin splits the entry point across jurisdictions and makes the audit story harder to tell without actually improving where data lives. Single origin, clean story.

---

**WAF at both the CloudFront edge and on the ALB.**

The CloudFront WAF handles OWASP Top 10 and blocks known bad IPs before anything hits Tokyo. That's the edge layer. The ALB WAF does something different — it blocks any request that doesn't have the CloudFront secret header. So if someone finds the ALB's DNS name and tries to hit it directly, the WAF blocks them. The two WAFs are doing different jobs: one filters for threats, one enforces that only CloudFront traffic can reach the origin.

Security groups alone can't do this. They work at the network layer and can't read HTTP headers.

---

## What's still not perfect

- **Egress rules on São Paulo and Osaka** are wide open (0.0.0.0/0 outbound). Fine for a lab, wouldn't be fine in production.
- **The Osaka EC2** had a user_data issue on first launch and the app was started manually via SSM. The Terraform was fixed but the instance hasn't been fully re-verified after the fix.
- **Route 53 failover** is deployed and the records are live but DNS propagation through Namecheap was still in progress as of 2026-03-16.
