# Lab 3 — Tokyo Stack Reference

**Compliance:** APPI — patient data stays in Japan  
**Primary region:** ap-northeast-1 (Tokyo)  
**AWS account:** 583001104385

---

## Why things are built the way they are

**Tokyo is the only data region.** PHI can't leave Japan under APPI, so the database lives in Tokyo and only in Tokyo. São Paulo and Osaka connect to it over Transit Gateway for all reads and writes.

**The RequireCloudFrontSecret rule is on the ALB WAF, not the CloudFront WAF.** The CloudFront-scope WAF runs between the viewer and CloudFront — before CloudFront adds the origin header. If you put the rule there it blocks everyone. The header only exists on the CloudFront-to-ALB leg, so the check lives on the REGIONAL WAF attached to the ALB.

**Secret header over IP allowlisting.** CloudFront's IP ranges change. Maintaining a list of them in security groups would break every time AWS updated it. A shared header value known only to the Terraform config and the WAF rule is stable and easy to audit.

**Transit Gateway, not VPC peering.** With three regions, VPC peering would mean multiple point-to-point connections and fragmented routing. TGW is a hub — each region attaches once. Traffic stays on the AWS backbone.

**RDS in private subnets, not publicly accessible.** Nothing in the design needs the DB to be reachable from the internet. `publicly_accessible = false`, no 0.0.0.0/0 on port 3306.

**SSM for EC2 access, not SSH.** No port 22, no key sprawl. Access is logged in CloudTrail. The instance profile has AmazonSSMManagedInstanceCore; all it needs is outbound HTTPS to SSM endpoints.

**Flask under systemd.** Restarts on crash, survives reboots. Important for a lab where instances get stopped and restarted constantly.

**EC2 Secrets Manager role is read-only.** The app only needs to fetch the DB credentials. It doesn't need to rotate or modify them, so it doesn't have that permission.

**HTTP to the origin from CloudFront.** TLS termination at the ALB would need an ACM certificate and HTTPS listener. Not needed for this lab. Viewer-to-CloudFront is upgradeable to HTTPS independently when needed.

**ASCII only in AWS description fields.** WAFv2 descriptions are validated against a strict regex. Em dashes and other non-ASCII characters cause a ValidationException. Learned this the hard way on deploy.

---

## Terraform outputs (Tokyo)

These are the values other stacks consume via `data.terraform_remote_state.tokyo`.

| Output | Value | Used by |
|---|---|---|
| `cloudfront_distribution_id` | E21VKJX8IT4I09 | Audit, CLI verification |
| `cloudfront_domain_name` | d1ukfjlu61n1r6.cloudfront.net | Health checks, docs |
| `waf_acl_arn` | arn:aws:wafv2:us-east-1:583001104385:global/webacl/lab3-waf-acl/... | Proof WAF is attached |
| `tokyo_alb_dns` | lab3-tokyo-alb-2005384345.ap-northeast-1.elb.amazonaws.com | CloudFront origin, Route 53 |
| `tokyo_rds_endpoint` | lab3-tokyo-mysql.clyg202mw62j.ap-northeast-1.rds.amazonaws.com | São Paulo + Osaka app config |
| `tokyo_rds_port` | 3306 | App config |
| `tokyo_vpc_id` | vpc-0686276a78477bd46 | TGW attachment |
| `tokyo_vpc_cidr` | 10.0.0.0/16 | SP + Osaka: route to Tokyo via TGW |
| `tokyo_tgw_id` | tgw-07c760214412bf700 | SP state: peering accepter, route |
| `tokyo_tgw_peering_attachment_id` | tgw-attach-069c3589989778681 | SP state: accepter resource |
| `tokyo_private_subnet_1_id` | subnet-0f6b4fcdc8d5771cc | TGW attachment, RDS subnet group |
| `tokyo_private_subnet_2_id` | subnet-0b16a9711e772a006 | TGW attachment, RDS subnet group |
| `tokyo_private_route_table_id` | rtb-0e65df33620674839 | SP/Osaka route targets |
| `tokyo_rds_sg_id` | sg-045d82a2ddec9f13f | Verification of SP/Osaka ingress rules |
| `tokyo_ec2_sg_id` | sg-0336d8660c8c5cac2 | Cross-region troubleshooting |
| `tokyo_db_name` | lab3db | App config |

São Paulo reads these via `data.terraform_remote_state.tokyo` with backend `local`, path `../tokyo/terraform.tfstate`. Apply Tokyo first.

---

## Live resource IDs

| Resource | ID |
|---|---|
| VPC | vpc-0686276a78477bd46 |
| EC2 | i-0dde4915a773fa365 |
| ALB ARN | arn:aws:elasticloadbalancing:ap-northeast-1:583001104385:loadbalancer/app/lab3-tokyo-alb/03f03473676189ea |
| RDS instance | db-MJMIT4RC55JREEXKSEHN5BTGTU |
| CloudFront | E21VKJX8IT4I09 |
| WAF (CloudFront scope) | 9a2f2c08-c9bb-45f8-9905-0027fe139d66 |
| WAF (ALB regional) | lab3-alb-waf (ap-northeast-1) |
| Tokyo TGW | tgw-07c760214412bf700 |
| TGW peering (SP) | tgw-attach-069c3589989778681 |
| TGW peering (Osaka) | tgw-attach-0ab9a7e2ac5e244bd |
| NAT gateway | nat-00de52da3ac8c39d6 |
| Private route table | rtb-0e65df33620674839 |
| Public route table | rtb-01dc8fbf0f06c30cb |
| ALB SG | sg-0c634be915ff62fca |
| EC2 SG | sg-0336d8660c8c5cac2 |
| RDS SG | sg-045d82a2ddec9f13f |
| Private subnet 1 | subnet-0f6b4fcdc8d5771cc (10.0.10.0/24, 1a) |
| Private subnet 2 | subnet-0b16a9711e772a006 (10.0.11.0/24, 1c) |
| Public subnet 1 | subnet-08ee0684faaabd440 (10.0.1.0/24, 1a) |
| Public subnet 2 | subnet-0f5aeb2b05fcdd63b (10.0.2.0/24, 1c) |
| IAM role | lab3-tokyo-ec2-role |
| Instance profile | lab3-tokyo-ec2-profile |
| São Paulo EC2 | i-069c5269912fccabd |
| Osaka EC2 | i-01ad3bc1822996657 |

---

## Traffic path

```
Viewer
 → CloudFront (d1ukfjlu61n1r6.cloudfront.net)
 → WAF CloudFront-scope (lab3-waf-acl, us-east-1) — OWASP + IP reputation
 → Tokyo ALB — CloudFront adds x-cloudfront-secret header
 → WAF REGIONAL (lab3-alb-waf, ap-northeast-1) — blocks missing/wrong header
 → EC2 Flask (port 5000)
 → Tokyo RDS MySQL (port 3306)
```

---

## Terraform file map (Tokyo)

| File | What it does |
|---|---|
| `provider.tf` | Default provider (ap-northeast-1) + alias `useast1` (us-east-1) for CloudFront and WAF |
| `variables.tf` | All input variables — CIDRs, TGW IDs, DB settings, AMI, profile |
| `terraform.tfvars` | Actual values for this environment — not committed |
| `main.tf` | VPC, subnets, IGW, NAT gateway, route tables |
| `sg.tf` | Security groups for ALB, EC2, RDS |
| `rds.tf` | MySQL RDS — encrypted, private, no public access |
| `ec2_app.tf` | EC2, IAM role, Flask via systemd, ALB, target group, listener |
| `cloudfront.tf` | CloudFront distribution — origin Tokyo ALB, CachingDisabled, secret header |
| `waf.tf` | CLOUDFRONT WAF (managed rules) + REGIONAL WAF on ALB (secret header rule) + association |
| `tgw.tf` | TGW, VPC attachment, peering to SP, accepter for Osaka |
| `routes.tf` | Private route table entries to SP and Osaka via TGW |
| `outputs.tf` | Everything listed in the outputs table above |

---

## Verification checks

```bash
# PHI only in Tokyo
aws rds describe-db-instances --region ap-northeast-1 \
  --query 'DBInstances[].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}'

aws rds describe-db-instances --region sa-east-1 \
  --query 'DBInstances[].DBInstanceIdentifier'

# RDS not publicly accessible
aws rds describe-db-instances --db-instance-identifier lab3-tokyo-mysql \
  --region ap-northeast-1 \
  --query 'DBInstances[0].PubliclyAccessible'

# TGW peering state
aws ec2 describe-transit-gateway-peering-attachments --region ap-northeast-1

# CloudFront WAF attached
aws cloudfront get-distribution --id E21VKJX8IT4I09 \
  --query 'Distribution.DistributionConfig.WebACLId'

# ALB WAF attached
aws wafv2 list-web-acls --scope REGIONAL --region ap-northeast-1

# No port 22 on EC2 SG
aws ec2 describe-security-groups --group-ids sg-0336d8660c8c5cac2 \
  --region ap-northeast-1 \
  --query 'SecurityGroups[0].IpPermissions'
```

---

## Gaps and known issues

- Egress rules on São Paulo and Osaka are wide open (0.0.0.0/0 outbound). Fine for a lab, not production.
- Osaka EC2 had a user_data issue on first launch — app was started manually via SSM. Terraform was fixed but not re-verified after.
- Route 53 is deployed but DNS propagation through Namecheap was still in progress as of 2026-03-16.
- Tokyo return route to São Paulo (10.1.0.0/16) was missing from live route table when checked during cost pause. Re-apply Tokyo Terraform after resume.
