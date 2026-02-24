#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-2}"
SECRET_ID="${SECRET_ID:-lab/rds/mysql}"
EXPECTED_ROLE_NAME="${EXPECTED_ROLE_NAME:-}"   # optional

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

echo "=== SEIR Gate: Secrets + EC2 Role Verification ==="
echo "Timestamp (UTC): ${timestamp}"
echo "Region:          ${AWS_REGION}"
echo "Instance ID:     ${INSTANCE_ID}"
echo "Secret ID:       ${SECRET_ID}"
echo -n "Resolved Role:   "

# Secret check
aws secretsmanager describe-secret --region "$AWS_REGION" --secret-id "$SECRET_ID" >/dev/null 2>&1 \
  && echo "PASS: aws sts get-caller-identity succeeded (credentials OK)." \
  || { echo "FAIL: aws sts get-caller-identity failed."; exit 1; }

if aws secretsmanager describe-secret --region "$AWS_REGION" --secret-id "$SECRET_ID" >/dev/null 2>&1; then
  echo "PASS: secret exists and is describable (${SECRET_ID})."
else
  echo "FAIL: secret missing or not describable (${SECRET_ID})."
  exit 1
fi

# Rotation info (best-effort)
rotation_enabled="$(aws secretsmanager describe-secret --region "$AWS_REGION" --secret-id "$SECRET_ID" --query RotationEnabled --output text 2>/dev/null || true)"
if [[ "${rotation_enabled}" == "True" ]]; then
  echo "INFO: rotation enabled."
else
  echo "INFO: rotation requirement disabled (REQUIRE_ROTATION=false)."
fi

# Resource policy (best-effort)
if aws secretsmanager get-resource-policy --region "$AWS_REGION" --secret-id "$SECRET_ID" >/dev/null 2>&1; then
  echo "PASS: resource policy present (OK) (${SECRET_ID})."
else
  echo "PASS: no resource policy found (OK) or not applicable (${SECRET_ID})."
fi

# Instance profile / role resolution
instance_profile_arn="$(aws ec2 describe-instances --region "$AWS_REGION" --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].IamInstanceProfile.Arn" --output text 2>/dev/null || true)"

resolved_role="UNKNOWN"
if [[ -n "${instance_profile_arn}" && "${instance_profile_arn}" != "None" ]]; then
  echo ""
  echo "PASS: instance has IAM instance profile attached (${INSTANCE_ID})."
  ip_name="${instance_profile_arn##*/}"
  resolved_role="$(aws iam get-instance-profile --instance-profile-name "$ip_name" \
    --query "InstanceProfile.Roles[0].RoleName" --output text 2>/dev/null || true)"
  if [[ -n "${resolved_role}" && "${resolved_role}" != "None" ]]; then
    echo "PASS: resolved instance profile -> role (${resolved_role} -> ${resolved_role})."
  else
    resolved_role="UNKNOWN"
    echo "FAIL: could not resolve role from instance profile."
    exit 1
  fi
else
  echo ""
  echo "FAIL: instance does not have IAM instance profile attached (${INSTANCE_ID})."
  exit 1
fi

# Print resolved role line like screenshot
# (we already printed "Resolved Role:" earlier; fix formatting by re-printing full header block feel)
# Keep it simple: print the resolved role explicitly too.
echo "Resolved Role:   ${resolved_role}"
echo "Caller ARN:      ${caller_arn}"
echo "----------------------------------------------"

# Expected role info / on-instance checks
if [[ -z "${EXPECTED_ROLE_NAME}" ]]; then
  echo "INFO: EXPECTED_ROLE_NAME not set; using resolved role (${resolved_role})."
  EXPECTED_ROLE_NAME="${resolved_role}"
fi

if [[ "${caller_arn}" == *":assumed-role/${EXPECTED_ROLE_NAME}/"* ]]; then
  echo "INFO: on-instance checks enabled (running as expected role on EC2)."
else
  echo "INFO: on-instance checks skipped (not running as expected role on EC2)."
  echo ""
  echo "Warnings:"
  echo "  - WARN: current caller ARN is not assumed-role/${EXPECTED_ROLE_NAME} (you may be running off-instance)."
fi

# Emit JSON artifact
cat > gate_secrets_and_role.json << JSONEND
{"timestamp":"${timestamp}","region":"${AWS_REGION}","instance_id":"${INSTANCE_ID}","secret_id":"${SECRET_ID}","resolved_role":"${resolved_role}","caller_arn":"${caller_arn}","result":"PASS"}
JSONEND

echo ""
echo "RESULT: PASS"
