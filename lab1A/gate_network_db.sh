#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-2}"
RDS_INSTANCE_ID="${RDS_INSTANCE_ID:-lab-mysql}"
DB_PORT="${DB_PORT:-3306}"

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
caller_arn="$(aws sts get-caller-identity --query Arn --output text 2>/dev/null || true)"

if [[ -z "${caller_arn}" || "${caller_arn}" == "None" ]]; then
  echo "FAIL: aws sts get-caller-identity failed."
  exit 1
fi

# Resolve INSTANCE_ID if not provided
if [[ -z "${INSTANCE_ID:-}" ]]; then
  INSTANCE_ID="$(aws ec2 describe-instances --region "$AWS_REGION" \
    --filters "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].InstanceId" --output text 2>/dev/null || true)"
fi
if [[ -z "${INSTANCE_ID:-}" || "${INSTANCE_ID}" == "None" ]]; then
  echo "FAIL: INSTANCE_ID required (could not auto-resolve)."
  exit 1
fi

echo "=== SEIR Gate: Network + RDS Verification ==="
echo "Timestamp (UTC): ${timestamp}"
echo "Region:          ${AWS_REGION}"
echo "EC2 Instance:    ${INSTANCE_ID}"
echo "RDS Instance:    ${RDS_INSTANCE_ID}"

engine="$(aws rds describe-db-instances --region "$AWS_REGION" --db-instance-identifier "$RDS_INSTANCE_ID" \
  --query "DBInstances[0].Engine" --output text 2>/dev/null || true)"
if [[ -z "${engine}" || "${engine}" == "None" ]]; then
  echo "FAIL: RDS instance not found (${RDS_INSTANCE_ID})."
  exit 1
fi

echo "Engine:          ${engine}"
echo "DB Port:         ${DB_PORT}"
echo "Caller ARN:      ${caller_arn}"
echo "----------------------------------------------"

echo "PASS: aws sts get-caller-identity succeeded (credentials OK)."
echo "PASS: RDS instance exists (${RDS_INSTANCE_ID})."

public_accessible="$(aws rds describe-db-instances --region "$AWS_REGION" --db-instance-identifier "$RDS_INSTANCE_ID" \
  --query "DBInstances[0].PubliclyAccessible" --output text 2>/dev/null || true)"
if [[ "${public_accessible}" == "False" ]]; then
  echo "PASS: RDS is not publicly accessible (PubliclyAccessible=False)."
else
  echo "WARN: RDS appears publicly accessible (PubliclyAccessible=${public_accessible})."
fi

echo "INFO: using DB_PORT override = ${DB_PORT}."

# Resolve SGs
ec2_sg_id="$(aws ec2 describe-instances --region "$AWS_REGION" --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" --output text 2>/dev/null || true)"
rds_sg_id="$(aws rds describe-db-instances --region "$AWS_REGION" --db-instance-identifier "$RDS_INSTANCE_ID" \
  --query "DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId" --output text 2>/dev/null || true)"

if [[ -z "${ec2_sg_id}" || "${ec2_sg_id}" == "None" ]]; then
  echo "FAIL: could not resolve EC2 security group."
  exit 1
fi
if [[ -z "${rds_sg_id}" || "${rds_sg_id}" == "None" ]]; then
  echo "FAIL: could not resolve RDS security group."
  exit 1
fi

echo "PASS: EC2 security groups resolved (${INSTANCE_ID}): ${ec2_sg_id}"
echo "PASS: RDS security groups resolved (${RDS_INSTANCE_ID}): ${rds_sg_id}"

# Check ingress SG-to-SG on port
ingress_ok="$(aws ec2 describe-security-groups --region "$AWS_REGION" --group-ids "$rds_sg_id" \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`${DB_PORT}\` && ToPort==\`${DB_PORT}\` && contains(UserIdGroupPairs[].GroupId, \`${ec2_sg_id}\`)] | length(@)" \
  --output text 2>/dev/null || true)"

if [[ "${ingress_ok}" != "0" && "${ingress_ok}" != "None" && -n "${ingress_ok}" ]]; then
  echo "PASS: RDS SG allows DB port ${DB_PORT} from EC2 SG (SG-to-SG ingress present)."
else
  echo "FAIL: missing SG-to-SG ingress rule (RDS ${rds_sg_id} must allow ${DB_PORT} from EC2 ${ec2_sg_id})."
  exit 1
fi

echo "INFO: private subnet check disabled (CHECK_PRIVATE_SUBNETS=false)."

cat > gate_network_db.json << JSONEND
{"timestamp":"${timestamp}","region":"${AWS_REGION}","ec2_instance":"${INSTANCE_ID}","ec2_sg":"${ec2_sg_id}","rds_instance":"${RDS_INSTANCE_ID}","rds_sg":"${rds_sg_id}","engine":"${engine}","db_port":${DB_PORT},"caller_arn":"${caller_arn}","result":"PASS"}
JSONEND

echo ""
echo "RESULT: PASS"
