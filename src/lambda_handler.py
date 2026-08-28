"""Lambda entrypoint for the monitoring stack.

A single Lambda is invoked by many EventBridge schedule rules. Each rule
supplies an event like:

    {"script": "check_rds_snapshots", "job": "rds-snapshots"}

The handler downloads s3://SCRIPTS_BUCKET/<script>.py, runs it as a
subprocess, and lets the script push metrics to the Prometheus Pushgateway
itself (via the monitoring_sdk layer). This keeps the Lambda stable: adding a
new monitor only requires a new file in monitoring-scripts/ + a new EventBridge
rule, never a Lambda redeploy.
"""

import boto3
import json
import os
import sys
import time
import tempfile
import subprocess


def _push_heartbeat(script, job, status):
    """Record that this monitor ran, so a dead/failing monitor is visible even
    when the script itself produced no metrics. Failures here are non-fatal."""
    try:
        from monitoring_sdk import Pushgateway, Metric

        ts = Metric(
            "monitoring_run_timestamp_seconds",
            "gauge",
            "Unix timestamp of the last run of this monitor",
        )
        st = Metric(
            "monitoring_run_status",
            "gauge",
            "1 = last run succeeded, 0 = failed/errored",
        )
        ts.add(int(time.time()), {"script": script, "monitored_job": job})
        st.add(1 if status == "success" else 0,
               {"script": script, "monitored_job": job, "status": status})

        # Push the heartbeat under its OWN job group ("monitoring-runner") so it
        # does NOT clobber the script's metrics (Pushgateway replaces the whole
        # job/instance group on each PUT).
        pgw = Pushgateway(
            os.environ.get("PUSHGATEWAY_URL", ""),
            job="monitoring-runner",
            instance=script,
        )
        pgw.push([ts, st])
    except Exception as e:
        print(f"heartbeat push failed: {e}", flush=True)


def handler(event, context):
    s3 = boto3.client("s3")
    bucket = os.environ["SCRIPTS_BUCKET"]
    script = (event or {}).get("script")
    job = (event or {}).get("job", script)

    if not script:
        _push_heartbeat(script or "unknown", job or "unknown", "error")
        return _resp("error", msg="event missing 'script' key")

    key = f"{script}.py"
    local = os.path.join(tempfile.gettempdir(), key)
    try:
        s3.download_file(bucket, key, local)
    except Exception as e:
        _push_heartbeat(script, job, "error")
        return _resp("error", script=script, msg=f"failed to download {key}: {e}")

    env = dict(os.environ)
    env["PUSHGATEWAY_URL"] = os.environ.get("PUSHGATEWAY_URL", "")
    env["JOB"] = job or script
    env["SCRIPT"] = script

    try:
        result = subprocess.run(
            [sys.executable, local],
            env=env,
            capture_output=True,
            text=True,
            timeout=300,
        )
    except subprocess.TimeoutExpired:
        _push_heartbeat(script, job, "error")
        return _resp("failure", script=script, msg="script timed out after 300s")
    except Exception as e:
        _push_heartbeat(script, job, "error")
        return _resp("error", script=script, msg=str(e))

    if result.returncode != 0:
        _push_heartbeat(script, job, "failure")
        return _resp(
            "failure",
            script=script,
            stdout=result.stdout,
            stderr=result.stderr,
        )

    _push_heartbeat(script, job, "success")
    return _resp("success", script=script, stdout=result.stdout)


def _resp(status, script=None, msg=None, stdout=None, stderr=None):
    return {
        "status": status,
        "script": script,
        "message": msg,
        "stdout": stdout,
        "stderr": stderr,
    }
