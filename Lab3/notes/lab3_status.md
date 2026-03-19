# Lab 3 Status

## Current Phase
Phase 1 — Tokyo base Terraform complete, one fix pending before apply

## What Is Done
- All 9 Tokyo .tf files written and on disk
- terraform init passed
- terraform.tfstate exists (partial apply may have run)
- Circular SG dependency resolved (rebuilt with aws_security_group_rule)
- sao_paulo_tgw_id variable added to variables.tf
- Peering attachment commented out in tgw.tf (needs Sao Paulo TGW ID)
- Peering output commented out in outputs.tf

## Active Blocker
- sg.tf line 139: description contains accented character in "Sao Paulo"
- AWS rejects non-ASCII characters in SG rule descriptions
- Fix: open sg.tf in Cursor, change to "MySQL from Sao Paulo VPC via TGW"
- Then run: terraform plan && terraform apply

## Fixed Decisions
| Decision | Value |
|---|---|
| Tokyo region | ap-northeast-1 |
| Sao Paulo region | sa-east-1 |
| Tokyo VPC CIDR | 10.0.0.0/16 |
| Sao Paulo VPC CIDR | 10.1.0.0/16 |
| Tokyo TGW ASN | 64512 |
| Sao Paulo TGW ASN | 64513 |
| Flask port | 5000 |
| DB port | 3306 |
| DB engine | MySQL 8.0 |
| Domain (Phase 6) | chewbacca-growls.com |
| AWS account | 583001104385 |
| Repo path | ~/Desktop/TWC/Armageddon/Lab3/ |

## Next Actions (in order)
1. Fix sg.tf line 139
2. terraform plan — confirm clean
3. terraform apply
4. Verify Tokyo ALB + RDS
5. Build Sao Paulo
