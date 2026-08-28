"""Example monitor: count S3 buckets without a lifecycle rule and expose a
gauge. Pushed to the Prometheus Pushgateway via the shared SDK layer.

Triggered by an EventBridge rule passing:
    {"script": "check_s3_lifecycle", "job": "s3-lifecycle"}
"""

import os
import boto3
from monitoring_sdk import Pushgateway, Metric


def main():
    region = os.environ.get("AWS_REGION", "us-east-1")
    client = boto3.client("s3", region_name=region)

    missing = Metric(
        "s3_buckets_missing_lifecycle",
        "gauge",
        "Number of S3 buckets without any lifecycle configuration",
    )
    total = Metric("s3_buckets_total", "gauge", "Total number of S3 buckets")

    buckets = [b["Name"] for b in client.list_buckets().get("Buckets", [])]
    count_missing = 0
    for name in buckets:
        try:
            client.get_bucket_lifecycle_configuration(Bucket=name)
        except client.exceptions.NoSuchLifecycleConfiguration:
            count_missing += 1
        except Exception:
            # access denied / not relevant -> skip
            pass

    total.add(len(buckets))
    missing.add(count_missing)

    pgw = Pushgateway(
        os.environ["PUSHGATEWAY_URL"], job=os.environ.get("JOB", "s3-lifecycle")
    )
    pgw.push([total, missing])
    print(f"{count_missing}/{len(buckets)} buckets missing lifecycle", flush=True)


if __name__ == "__main__":
    main()
