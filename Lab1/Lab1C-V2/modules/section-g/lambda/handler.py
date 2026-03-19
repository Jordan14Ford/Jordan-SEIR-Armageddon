import datetime
import json
import os
import time

import boto3

logs = boto3.client("logs")
ssm = boto3.client("ssm")
secrets = boto3.client("secretsmanager")
s3 = boto3.client("s3")
sns = boto3.client("sns")
bedrock = boto3.client("bedrock-runtime")

REPORT_BUCKET = os.environ["REPORT_BUCKET"]
APP_LOG_GROUP = os.environ["APP_LOG_GROUP"]
WAF_LOG_GROUP = os.environ["WAF_LOG_GROUP"]
SECRET_ID = os.environ["SECRET_ID"]
SSM_PARAM_PATH = os.environ["SSM_PARAM_PATH"]
MODEL_ID = os.environ["BEDROCK_MODEL_ID"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def run_insights_query(log_group, query, start_ts, end_ts):
    query_id = logs.start_query(
        logGroupName=log_group,
        startTime=start_ts,
        endTime=end_ts,
        queryString=query,
        limit=50,
    )["queryId"]

    for _ in range(20):
        response = logs.get_query_results(queryId=query_id)
        status = response.get("status")
        if status in ("Complete", "Failed", "Cancelled", "Timeout"):
            return {"status": status, "results": response.get("results", [])}
        time.sleep(1)

    return {"status": "Timeout", "results": []}


def get_params_by_path(path):
    output = {}
    token = None
    while True:
        kwargs = {"Path": path, "Recursive": True, "WithDecryption": True}
        if token:
            kwargs["NextToken"] = token
        response = ssm.get_parameters_by_path(**kwargs)
        for parameter in response.get("Parameters", []):
            output[parameter["Name"]] = parameter["Value"]
        token = response.get("NextToken")
        if not token:
            break
    return output


def get_secret_payload(secret_id):
    secret_string = secrets.get_secret_value(SecretId=secret_id)["SecretString"]
    return json.loads(secret_string)


def invoke_bedrock(prompt):
    body = json.dumps(
        {
            "inputText": prompt,
            "textGenerationConfig": {
                "maxTokenCount": 1200,
                "temperature": 0.2,
                "topP": 0.9,
            },
        }
    )
    response = bedrock.invoke_model(
        modelId=MODEL_ID,
        contentType="application/json",
        accept="application/json",
        body=body,
    )
    return json.loads(response["body"].read())


def lambda_handler(event, context):
    now = int(time.time())
    start_ts = now - (15 * 60)

    app_errors = run_insights_query(
        APP_LOG_GROUP,
        "fields @timestamp, @message | filter @message like /ERROR|db|timeout/i | sort @timestamp desc | limit 30",
        start_ts,
        now,
    )
    waf_summary = run_insights_query(
        WAF_LOG_GROUP,
        "fields action | stats count() as hits by action | sort hits desc",
        start_ts,
        now,
    )

    params = get_params_by_path(SSM_PARAM_PATH)
    secret = get_secret_payload(SECRET_ID)

    incident_id = f"{datetime.datetime.utcnow().strftime('%Y%m%d-%H%M%S')}"
    evidence = {
        "incident_id": incident_id,
        "event": event,
        "window": {"start": start_ts, "end": now},
        "app_errors": app_errors,
        "waf_summary": waf_summary,
        "params": params,
        "secret_meta": {
            "host": secret.get("host"),
            "port": secret.get("port"),
            "dbname": secret.get("dbname"),
            "username": secret.get("username"),
        },
    }

    prompt = (
        "Write a concise incident report in markdown using only this evidence JSON:\n"
        + json.dumps(evidence, indent=2)
    )
    bedrock_output = invoke_bedrock(prompt)

    json_key = f"reports/{incident_id}.json"
    md_key = f"reports/{incident_id}.md"

    s3.put_object(Bucket=REPORT_BUCKET, Key=json_key, Body=json.dumps(evidence, indent=2).encode("utf-8"))
    s3.put_object(Bucket=REPORT_BUCKET, Key=md_key, Body=json.dumps(bedrock_output, indent=2).encode("utf-8"))

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=f"IR Report Ready {incident_id}",
        Message=f"Report: s3://{REPORT_BUCKET}/{md_key}\nEvidence: s3://{REPORT_BUCKET}/{json_key}",
    )

    return {"ok": True, "incident_id": incident_id}
