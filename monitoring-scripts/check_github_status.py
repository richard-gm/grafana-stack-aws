"""Monitor GitHub's own availability.

Two signals are pushed to the Prometheus Pushgateway:

1. GitHub API reachability  -> GET https://api.github.com/rate_limit
2. GitHub status page        -> https://www.githubstatus.com/api/v2/summary.json
                                (per-component operational/degraded/outage state)

Status values are mapped to a numeric severity so Grafana can alert on
`github_component_status > 0` or `github_api_reachable == 0`.

Triggered by an EventBridge rule passing:
    {"script": "check_github_status", "job": "github-status"}
"""

import os
import sys
import urllib.request
import urllib.error

from monitoring_sdk import Pushgateway, Metric

STATUS_PAGE = "https://www.githubstatus.com/api/v2/summary.json"
API_PROBE = "https://api.github.com/rate_limit"

# Statuspage.io component status -> severity
SEVERITY = {
    "operational": 0,
    "under_maintenance": 1,
    "degraded_performance": 1,
    "partial_outage": 2,
    "major_outage": 3,
}

# Overall indicator -> severity
OVERALL = {
    "none": 0,
    "minor": 1,
    "major": 2,
    "critical": 3,
}


def _get_json(url, timeout=10):
    req = urllib.request.Request(url, headers={"User-Agent": "aws-monitoring-script"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.status, json.loads(resp.read().decode("utf-8"))


def main():
    import json

    api_reachable = Metric(
        "github_api_reachable", "gauge", "1 if the GitHub API responded 200"
    )
    overall = Metric(
        "github_overall_status", "gauge", "Overall GitHub status severity (0=ok,3=critical)"
    )
    component = Metric(
        "github_component_status",
        "gauge",
        "Per-component GitHub status severity (0=operational,3=major_outage)",
    )

    # 1. API reachability
    try:
        status, _ = _get_json(API_PROBE)
        api_reachable.add(1 if status == 200 else 0)
    except Exception as e:
        print(f"github api probe failed: {e}", flush=True)
        api_reachable.add(0)

    # 2. Status page components
    try:
        status, data = _get_json(STATUS_PAGE)
        ind = data.get("status", {}).get("indicator", "none")
        overall.add(OVERALL.get(ind, 1), {"indicator": ind})

        for comp in data.get("components", []):
            name = comp.get("name", "unknown")
            st = comp.get("status", "operational")
            component.add(SEVERITY.get(st, 1), {"component": name, "status": st})
    except Exception as e:
        print(f"github status page fetch failed: {e}", flush=True)
        overall.add(1, {"indicator": "unknown"})
        component.add(1, {"component": "status_page", "status": "unknown"})

    pgw = Pushgateway(
        os.environ["PUSHGATEWAY_URL"],
        job=os.environ.get("JOB", "github-status"),
    )
    pgw.push([api_reachable, overall, component])
    print("pushed github status metrics", flush=True)


if __name__ == "__main__":
    main()
