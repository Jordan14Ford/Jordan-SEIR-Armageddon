# Lab 1B Incident Runbook

## 1) Acknowledge

```bash
aws cloudwatch describe-alarms \
  --alarm-name lab-db-connection-failure \
  --query "MetricAlarms[].StateValue"
```

## 2) Observe

```bash
aws logs filter-log-events \
  --log-group-name /aws/ec2/lab-rds-app \
  --filter-pattern "ERROR"
```

Classify root cause:

- credential drift
- network block
- database interruption

## 3) Validate config sources

```bash
aws ssm get-parameters \
  --names /lab/db/endpoint /lab/db/port /lab/db/name \
  --with-decryption

aws secretsmanager get-secret-value \
  --secret-id lab/rds/mysql
```

## 4) Recover

- Credential drift: sync DB password and secret value.
- Network block: restore EC2 SG access to RDS on 3306.
- DB stop: start RDS and wait until `available`.

## 5) Validate recovery

```bash
curl http://<EC2_IP>/list

aws cloudwatch describe-alarms \
  --alarm-name lab-db-connection-failure \
  --query "MetricAlarms[].StateValue"
```

