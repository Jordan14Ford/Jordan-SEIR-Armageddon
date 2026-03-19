# Lab 3 Build Order

## Phase 0 — Setup
- [x] Create Lab3/ folder structure
- [x] Create notes/ files
- [x] Confirm AWS credentials active (aws sts get-caller-identity)
- [x] Lock CIDRs: Tokyo 10.0.0.0/16, Sao Paulo 10.1.0.0/16

## Phase 1 — Tokyo Base
- [x] provider.tf
- [x] variables.tf
- [x] main.tf (VPC, subnets, IGW, NAT, route tables)
- [x] sg.tf (ALB, EC2, RDS security groups)
- [x] rds.tf (MySQL 8.0, private subnets, encrypted)
- [x] ec2_app.tf (IAM role, EC2, ALB, target group)
- [x] outputs.tf
- [x] tgw.tf (TGW + VPC attachment — peering commented out until Phase 3)
- [x] routes.tf
- [ ] Fix sg.tf line 139 — remove accented character from description
- [ ] terraform plan — clean pass
- [ ] terraform apply
- [ ] Verify: curl ALB /health returns 200
- [ ] Verify: RDS exists in ap-northeast-1
- [ ] Verify: RDS does NOT exist in sa-east-1

## Phase 2 — Sao Paulo Base
- [ ] touch all sao-paulo/ files
- [ ] provider.tf (sa-east-1)
- [ ] variables.tf (reads Tokyo outputs via remote_state)
- [ ] main.tf (VPC, subnets, IGW, NAT, route tables)
- [ ] sg.tf (ALB, EC2 only — no RDS SG)
- [ ] ec2_app.tf (Flask app pointed at Tokyo RDS endpoint)
- [ ] outputs.tf
- [ ] tgw.tf (Sao Paulo TGW + VPC attachment — peering accepter commented out until Phase 3)
- [ ] routes.tf
- [ ] terraform init && terraform plan
- [ ] terraform apply
- [ ] Verify: Sao Paulo ALB /health returns 200
- [ ] Verify: No RDS in sa-east-1

## Phase 3 — TGW Peering
- [ ] Get Sao Paulo TGW ID from state
- [ ] Set sao_paulo_tgw_id in Tokyo terraform.tfvars
- [ ] Uncomment peering attachment in tokyo/tgw.tf
- [ ] Uncomment peering accepter in sao-paulo/tgw.tf
- [ ] Apply Tokyo — peering attachment created (status: pending-acceptance)
- [ ] Apply Sao Paulo — peering accepter accepts it (status: available)
- [ ] Verify peering is available in both regions:
      aws ec2 describe-transit-gateway-peering-attachments --region ap-northeast-1
      aws ec2 describe-transit-gateway-peering-attachments --region sa-east-1

## Phase 4 — Routes + SG Updates
- [ ] Verify Tokyo private RT has route: 10.1.0.0/16 via Tokyo TGW
- [ ] Verify Sao Paulo private RT has route: 10.0.0.0/16 via Sao Paulo TGW
- [ ] Verify Tokyo RDS SG allows 3306 from 10.1.0.0/16
- [ ] Verify Sao Paulo EC2 SG allows outbound 3306 to 10.0.0.0/16

## Phase 5 — Corridor Verification
- [ ] SSM into Sao Paulo EC2
- [ ] Run mysql from Sao Paulo EC2 to Tokyo RDS endpoint on port 3306
- [ ] Verify connection succeeds
- [ ] Verify Sao Paulo Flask /db-check returns {"db": "reachable"}
- [ ] Save verification output to verifications/corridor_proof.txt

## Phase 6 — CloudFront + WAF (adapt from Lab 2A)
- [ ] Adapt lab2_cloudfront_alb.tf for Lab 3 Tokyo ALB origin
- [ ] Adapt lab2_cloudfront_shield_waf.tf
- [ ] Origin cloaking: restrict ALB SG to CloudFront prefix list
- [ ] Verify: https://chewbacca-growls.com returns 200
- [ ] Verify: direct ALB access times out

## Phase 7 — Lab 3B Audit Pack
- [ ] Configure WAF logging to CloudWatch
- [ ] Configure CloudFront standard logs to S3
- [ ] Wire CloudTrail in both regions
- [ ] Run malgus_residency_proof.py
- [ ] Run malgus_tgw_corridor_proof.py
- [ ] Run malgus_cloudtrail_last_changes.py
- [ ] Run malgus_waf_summary.py
- [ ] Run malgus_cloudfront_log_explainer.py
- [ ] Collect CLI evidence for all 5 proof files
- [ ] Write narrative.md
- [ ] Push audit-pack/ to GitHub
