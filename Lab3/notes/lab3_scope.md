# Lab 3 Minimum Pass Scope

## Tokyo (ap-northeast-1)
- VPC (10.0.0.0/16)
- Public + private subnets across 2 AZs
- IGW, NAT Gateway, route tables
- Security groups (ALB, EC2, RDS)
- RDS MySQL 8.0 in private subnets — only database in the entire lab
- EC2 app tier running Flask
- ALB in public subnets
- TGW + VPC attachment
- Outputs exported for Sao Paulo to consume

## Sao Paulo (sa-east-1)
- VPC (10.1.0.0/16)
- Public + private subnets across 2 AZs
- IGW, NAT Gateway, route tables
- Security groups (ALB, EC2)
- EC2 app tier running Flask — connects to Tokyo RDS over TGW
- ALB in public subnets
- TGW + VPC attachment
- NO RDS — compute only, this is the APPI requirement

## Cross-Region Corridor
- Tokyo TGW initiates peering attachment toward Sao Paulo
- Sao Paulo TGW accepts the peering attachment
- Tokyo private route table: 10.1.0.0/16 via Tokyo TGW
- Sao Paulo private route table: 10.0.0.0/16 via Sao Paulo TGW
- Tokyo RDS SG: inbound 3306 from 10.1.0.0/16 (Sao Paulo CIDR)
- Sao Paulo EC2 SG: outbound 3306 to 10.0.0.0/16 (Tokyo CIDR)

## Lab 3B Audit Deliverables
- audit-pack/01_data-residency-proof.txt
- audit-pack/02_edge-proof-cloudfront.txt
- audit-pack/03_waf-proof.txt
- audit-pack/04_cloudtrail-change-proof.txt
- audit-pack/05_network-corridor-proof.txt
- audit-pack/evidence.json
- audit-pack/narrative.md
