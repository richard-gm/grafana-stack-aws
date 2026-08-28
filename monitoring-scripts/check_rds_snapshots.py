"""Example monitor: report the age (seconds) of the latest automated RDS snapshot
per DB instance. Pushed to the Prometheus Pushgateway via the shared SDK layer.

Triggered by an EventBridge rule passing:
    {"script": "check_rds_snapshots", "job": "rds-snapshots"}
"""

import os
import time
import boto3
from monitoring_sdk import Pushgateway, Metric


def main():
    region = os.environ.get("AWS_REGION", "us-east-1")
    client = boto3.client("rds", region_name=region)

    age = Metric(
        "rds_latest_snapshot_age_seconds",
        "gauge",
        "Age of the latest automated RDS snapshot in seconds",
    )

    instances = client.describe_db_instances().get("DBInstances", [])
    for db in instances:
        ident = db["DBInstanceIdentifier"]
        try:
            snaps = client.describe_db_snapshots(
                DBInstanceIdentifier=ident, SnapshotType="automated"
            ).get("DBSnapshots", [])
        except Exception as e:
            print(f"skip {ident}: {e}", flush=True)
            continue

        if not snaps:
            age.add(-1, {"db": ident})
            continue

        latest = max(snaps, key=lambda s: s["SnapshotCreateTime"])
        seconds = int(time.time() - latest["SnapshotCreateTime"].timestamp())
        age.add(seconds, {"db": ident})

    pgw = Pushgateway(
        os.environ["PUSHGATEWAY_URL"], job=os.environ.get("JOB", "rds-snapshots")
    )
    pgw.push([age])
    print(f"pushed {len(instances)} db instances", flush=True)


if __name__ == "__main__":
    main()
