#!/bin/bash
set -euxo pipefail

dnf update -y
dnf install -y python3-pip amazon-cloudwatch-agent
pip3 install --upgrade pip
pip3 install flask pymysql boto3

mkdir -p /opt/rdsapp

cat >/opt/rdsapp/app.py <<'PY'
import json
import logging
import os

import boto3
import pymysql
from flask import Flask, request

REGION = os.environ.get("AWS_REGION", "us-east-1")
SECRET_ID = os.environ.get("SECRET_ID", "lab/rds/mysql")
DB_ENDPOINT_PARAM = os.environ.get("DB_ENDPOINT_PARAM", "/lab/db/endpoint")
DB_PORT_PARAM = os.environ.get("DB_PORT_PARAM", "/lab/db/port")
DB_NAME_PARAM = os.environ.get("DB_NAME_PARAM", "/lab/db/name")

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("lab1b-app")

ssm = boto3.client("ssm", region_name=REGION)
secrets = boto3.client("secretsmanager", region_name=REGION)
cloudwatch = boto3.client("cloudwatch", region_name=REGION)

def emit_db_error():
    cloudwatch.put_metric_data(
        Namespace="Lab/RDSApp",
        MetricData=[{
            "MetricName": "DBConnectionErrors",
            "Value": 1,
            "Unit": "Count"
        }]
    )

def get_db_cfg():
    secret = json.loads(secrets.get_secret_value(SecretId=SECRET_ID)["SecretString"])
    params = ssm.get_parameters(
        Names=[DB_ENDPOINT_PARAM, DB_PORT_PARAM, DB_NAME_PARAM],
        WithDecryption=True,
    )
    values = {p["Name"]: p["Value"] for p in params.get("Parameters", [])}

    return {
        "host": values.get(DB_ENDPOINT_PARAM, secret.get("host")),
        "port": int(values.get(DB_PORT_PARAM, secret.get("port", 3306))),
        "dbname": values.get(DB_NAME_PARAM, secret.get("dbname", "labdb")),
        "username": secret["username"],
        "password": secret["password"],
    }

def get_conn():
    cfg = get_db_cfg()
    return pymysql.connect(
        host=cfg["host"],
        user=cfg["username"],
        password=cfg["password"],
        port=cfg["port"],
        database=cfg["dbname"],
        autocommit=True,
        connect_timeout=5,
    )

@app.route("/")
def home():
    return "Lab 1B app running. Endpoints: /init /add?note=hello /list"

@app.route("/init")
def init_db():
    try:
        cfg = get_db_cfg()
        conn = pymysql.connect(
            host=cfg["host"],
            user=cfg["username"],
            password=cfg["password"],
            port=cfg["port"],
            autocommit=True,
        )
        cur = conn.cursor()
        cur.execute(f"CREATE DATABASE IF NOT EXISTS `{cfg['dbname']}`;")
        cur.execute(f"USE `{cfg['dbname']}`;")
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS notes (
                id INT AUTO_INCREMENT PRIMARY KEY,
                note VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """
        )
        cur.close()
        conn.close()
        return {"status": "initialized"}, 200
    except Exception as exc:
        logger.exception("ERROR: DB init failed")
        emit_db_error()
        return {"error": str(exc)}, 500

@app.route("/add")
def add():
    note = request.args.get("note", "").strip()
    if not note:
        return {"error": "missing note parameter"}, 400
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("INSERT INTO notes(note) VALUES(%s);", (note,))
        cur.close()
        conn.close()
        return {"status": "added", "note": note}, 200
    except Exception as exc:
        logger.exception("ERROR: DB insert failed")
        emit_db_error()
        return {"error": str(exc)}, 500

@app.route("/list")
def list_notes():
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT id, note, created_at FROM notes ORDER BY created_at DESC;")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return {"notes": [{"id": r[0], "note": r[1], "created_at": str(r[2])} for r in rows]}, 200
    except Exception as exc:
        logger.exception("ERROR: DB list failed")
        emit_db_error()
        return {"error": str(exc)}, 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
PY

cat >/etc/systemd/system/rdsapp.service <<'SERVICE'
[Unit]
Description=EC2 to RDS Notes App
After=network.target

[Service]
WorkingDirectory=/opt/rdsapp
Environment=AWS_REGION=us-east-1
Environment=SECRET_ID=lab/rds/mysql
Environment=DB_ENDPOINT_PARAM=/lab/db/endpoint
Environment=DB_PORT_PARAM=/lab/db/port
Environment=DB_NAME_PARAM=/lab/db/name
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always
StandardOutput=append:/var/log/rdsapp.log
StandardError=append:/var/log/rdsapp.log

[Install]
WantedBy=multi-user.target
SERVICE

cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWEOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/rdsapp.log",
            "log_group_name": "/aws/ec2/lab-rds-app",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 7
          }
        ]
      }
    }
  }
}
CWEOF

systemctl daemon-reload
systemctl enable rdsapp
systemctl start rdsapp
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
