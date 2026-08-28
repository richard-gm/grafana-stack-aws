"""Minimal Prometheus Pushgateway client (stdlib only, no external deps).

Usage:
    from monitoring_sdk import Pushgateway, Metric

    m = Metric("rds_snapshot_age_seconds", "gauge", "Age of latest snapshot")
    m.add(1234, {"db": "prod-orders"})
    m.add(5678, {"db": "prod-billing"})

    pgw = Pushgateway("http://pushgateway.monitoring:9091", job="rds-snapshots")
    pgw.push([m])
"""

import os
import urllib.request
import urllib.error


class Metric:
    """A single Prometheus metric with one or more samples."""

    def __init__(self, name, mtype, help_text=None):
        if mtype not in ("gauge", "counter", "histogram", "summary", "untyped"):
            raise ValueError(f"invalid metric type: {mtype}")
        self.name = name
        self.mtype = mtype
        self.help_text = help_text
        self.samples = []  # list of (value, labels)

    def add(self, value, labels=None):
        self.samples.append((value, labels or {}))


class Pushgateway:
    def __init__(self, url, job, instance=None):
        self.base = url.rstrip("/")
        self.job = job
        self.instance = instance or job

    def _uri(self):
        uri = f"{self.base}/metrics/job/{self.job}"
        if self.instance:
            uri += f"/instance/{self.instance}"
        return uri

    @staticmethod
    def _render(metrics):
        lines = []
        for m in metrics:
            if m.help_text:
                lines.append(f"# HELP {m.name} {m.help_text}")
            lines.append(f"# TYPE {m.name} {m.mtype}")
            for value, labels in m.samples:
                if labels:
                    label_str = "{" + ",".join(
                        f'{k}="{v}"' for k, v in labels.items()
                    ) + "}"
                else:
                    label_str = ""
                lines.append(f"{m.name}{label_str} {value}")
        return "\n".join(lines) + "\n"

    def push(self, metrics):
        body = self._render(metrics)
        req = urllib.request.Request(
            self._uri(),
            data=body.encode("utf-8"),
            method="PUT",
            headers={"Content-Type": "text/plain; version=0.0.4"},
        )
        try:
            urllib.request.urlopen(req, timeout=10)
        except urllib.error.HTTPError as e:
            raise RuntimeError(
                f"Pushgateway PUT failed: {e.code} {e.read().decode('utf-8')}"
            )
        except urllib.error.URLError as e:
            raise RuntimeError(f"Pushgateway unreachable: {e.reason}")

    def delete(self):
        """Delete all metrics for this job/instance group."""
        req = urllib.request.Request(self._uri(), method="DELETE")
        try:
            urllib.request.urlopen(req, timeout=10)
        except urllib.error.HTTPError as e:
            if e.code != 404:
                raise RuntimeError(f"Pushgateway DELETE failed: {e.code}")
        except urllib.error.URLError as e:
            raise RuntimeError(f"Pushgateway unreachable: {e.reason}")


def default_pushgateway():
    """Build a Pushgateway from the standard Lambda environment variables."""
    return Pushgateway(
        os.environ["PUSHGATEWAY_URL"],
        job=os.environ.get("JOB", "monitoring"),
        instance=os.environ.get("SCRIPT"),
    )
