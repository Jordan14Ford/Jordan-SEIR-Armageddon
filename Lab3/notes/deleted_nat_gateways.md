# Deleted NAT Gateways - Lab 1 & Lab 2

Deleted on: 2026-03-13 to pause AWS costs.

## us-east-1: cloudyjones-nat-gw

| Property | Value |
|----------|-------|
| NAT Gateway ID | `nat-05c65354648923bb4` |
| Name | cloudyjones-nat-gw |
| VPC ID | `vpc-0e61a7b7044f6dfb2` |
| Subnet ID | `subnet-0b169845e69e9903a` |
| Elastic IP Allocation ID | `eipalloc-0b5e6a54e81da532e` |
| Public IP | 98.87.123.42 |
| Private IP | 10.0.1.29 |
| Created | 2026-03-06T02:45:30+00:00 |
| Project Tag | cloudyjones |

## us-east-2: (unnamed)

| Property | Value |
|----------|-------|
| NAT Gateway ID | `nat-0457e1e2c7fa6c68b` |
| Name | (none) |
| VPC ID | `vpc-0d2b8640f525ff24b` |
| Subnet ID | `subnet-06c9bbfcaacc81782` |
| Elastic IP Allocation ID | `eipalloc-0bc222374f3fab13a` |
| Public IP | 16.59.76.248 |
| Private IP | 10.236.2.11 |
| Created | 2026-03-09T18:51:51+00:00 |

## To Recreate

Use Terraform to recreate these, or manually:

```bash
# us-east-1
aws ec2 create-nat-gateway --region us-east-1 \
  --subnet-id subnet-0b169845e69e9903a \
  --allocation-id eipalloc-0b5e6a54e81da532e

# us-east-2
aws ec2 create-nat-gateway --region us-east-2 \
  --subnet-id subnet-06c9bbfcaacc81782 \
  --allocation-id eipalloc-0bc222374f3fab13a
```

Note: The Elastic IPs are preserved (not deleted) so they can be reused.
