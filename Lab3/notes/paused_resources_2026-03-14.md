# Paused Resources - Lab 3

Paused on: 2026-03-14 to save costs overnight.

## Resumed - 2026-03-15

Environment resumed on 2026-03-15.

EC2 instances started:
- Tokyo (ap-northeast-1): i-0dde4915a773fa365 — running
- São Paulo (sa-east-1): i-069c5269912fccabd — running
- Osaka (ap-northeast-3): i-01ad3bc1822996657 — running

RDS started:
- Tokyo: lab3-tokyo-mysql — available
- Endpoint: lab3-tokyo-mysql.clyg202mw62j.ap-northeast-1.rds.amazonaws.com

NAT Gateways recreated (new IDs — old IDs are blackholed):
- Tokyo: nat-00de52da3ac8c39d6 — subnet-08ee0684faaabd440
- Osaka: nat-03f3384b28757be08 — subnet-059cfd0f30870bc6c
- São Paulo: nat-055a01824da1960bd — subnet-0286472188115744d

Route tables updated to point 0.0.0.0/0 at new NAT Gateway IDs:
- Tokyo private rt: rtb-0e65df33620674839
- Osaka private rt: rtb-08a6e8298a1613692
- São Paulo private rt: rtb-0978dd3df558e74a8

## Stopped EC2 Instances

| Region | Instance ID | Name |
|--------|-------------|------|
| Tokyo (ap-northeast-1) | `i-0dde4915a773fa365` | lab3-tokyo-app-ec2 |
| Osaka (ap-northeast-3) | `i-01ad3bc1822996657` | lab3-osaka-app-ec2 |
| São Paulo (sa-east-1) | `i-069c5269912fccabd` | lab3-sao-paulo-app-ec2 |

### To restart:
```bash
aws ec2 start-instances --region ap-northeast-1 --instance-ids i-0dde4915a773fa365
aws ec2 start-instances --region ap-northeast-3 --instance-ids i-01ad3bc1822996657
aws ec2 start-instances --region sa-east-1 --instance-ids i-069c5269912fccabd
```

## Stopped RDS

| Region | Instance ID | Endpoint |
|--------|-------------|----------|
| Tokyo | `lab3-tokyo-mysql` | lab3-tokyo-mysql.clyg202mw62j.ap-northeast-1.rds.amazonaws.com |

### To restart:
```bash
aws rds start-db-instance --region ap-northeast-1 --db-instance-identifier lab3-tokyo-mysql
```

Note: RDS auto-restarts after 7 days if not manually started.

## Deleted NAT Gateways

| Region | NAT Gateway ID | Subnet ID | EIP Allocation ID |
|--------|----------------|-----------|-------------------|
| Tokyo | `nat-03a086f5e39e3ab4a` | `subnet-08ee0684faaabd440` | `eipalloc-032d61f250a61e162` |
| Osaka | `nat-0b842685552a33035` | `subnet-059cfd0f30870bc6c` | `eipalloc-035bb0703b788ea02` |
| São Paulo | `nat-0b214b63a002d2ea4` | `subnet-0286472188115744d` | `eipalloc-048d7f371b229a4ca` |

### To recreate:
```bash
# Tokyo
aws ec2 create-nat-gateway --region ap-northeast-1 \
  --subnet-id subnet-08ee0684faaabd440 \
  --allocation-id eipalloc-032d61f250a61e162

# Osaka
aws ec2 create-nat-gateway --region ap-northeast-3 \
  --subnet-id subnet-059cfd0f30870bc6c \
  --allocation-id eipalloc-035bb0703b788ea02

# São Paulo
aws ec2 create-nat-gateway --region sa-east-1 \
  --subnet-id subnet-0286472188115744d \
  --allocation-id eipalloc-048d7f371b229a4ca
```

After recreating NAT Gateways, update the private route tables to point to the new NAT Gateway IDs.

## Estimated Savings

| Resource | Hourly Cost | Daily Savings |
|----------|-------------|---------------|
| 3x EC2 t3.micro | ~$0.03 | ~$0.72 |
| 1x RDS db.t3.micro | ~$0.02 | ~$0.48 |
| 3x NAT Gateway | ~$0.14 | ~$3.36 |
| **Total** | ~$0.19/hr | ~$4.56/day |

## Quick Resume Script

```bash
# 1. Start RDS first (takes longest)
aws rds start-db-instance --region ap-northeast-1 --db-instance-identifier lab3-tokyo-mysql

# 2. Recreate NAT Gateways
aws ec2 create-nat-gateway --region ap-northeast-1 --subnet-id subnet-08ee0684faaabd440 --allocation-id eipalloc-032d61f250a61e162
aws ec2 create-nat-gateway --region ap-northeast-3 --subnet-id subnet-059cfd0f30870bc6c --allocation-id eipalloc-035bb0703b788ea02
aws ec2 create-nat-gateway --region sa-east-1 --subnet-id subnet-0286472188115744d --allocation-id eipalloc-048d7f371b229a4ca

# 3. Wait for NAT Gateways to be available (~2 min)
sleep 120

# 4. Start EC2 instances
aws ec2 start-instances --region ap-northeast-1 --instance-ids i-0dde4915a773fa365
aws ec2 start-instances --region ap-northeast-3 --instance-ids i-01ad3bc1822996657
aws ec2 start-instances --region sa-east-1 --instance-ids i-069c5269912fccabd

# 5. Update route tables with new NAT Gateway IDs (check aws ec2 describe-nat-gateways output)
```

---

Next steps after resume:
- Run terraform apply in tokyo/ to restore missing return route
- Verify /health endpoints on all three ALBs
- Run connectivity test from São Paulo EC2 to Tokyo RDS port 3306
- Refresh audit-pack evidence files 01, 04, 05
- Update evidence.json with current resource IDs
