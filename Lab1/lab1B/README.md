# Lab 1B - Operations and Incident Response

This folder now contains the operational user data needed for Lab 1B.

## What this build now does

- Uses both Parameter Store (`/lab/db/*`) and Secrets Manager (`lab/rds/mysql`) at runtime.
- Writes application logs to `/var/log/rdsapp.log`.
- Ships logs to CloudWatch Logs group `/aws/ec2/lab-rds-app`.
- Emits custom metric `Lab/RDSApp:DBConnectionErrors` on DB failures.

## Deploy

1. Paste `lab1b-user-data.sh` into EC2 user data.
2. Make sure EC2 role can read:
   - SSM params under `/lab/db/*`
   - Secret `lab/rds/mysql`
   - `cloudwatch:PutMetricData` for `Lab/RDSApp`
3. Confirm service:
   - `sudo systemctl status rdsapp`
   - `sudo journalctl -u rdsapp -n 100 --no-pager`

## Verification

- `curl http://<EC2_IP>/init`
- `curl "http://<EC2_IP>/add?note=first_note"`
- `curl http://<EC2_IP>/list`
- `aws logs filter-log-events --log-group-name /aws/ec2/lab-rds-app --filter-pattern "ERROR"`
- `aws cloudwatch describe-alarms --alarm-name-prefix lab-db-connection`

