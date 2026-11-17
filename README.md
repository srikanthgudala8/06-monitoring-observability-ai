> **Phase 6 of the 60-day journey** (Days 50-60). Day-by-day plan: **[LEARNING.md](LEARNING.md)**.
> Extras: `ai/` (alert triage tool with optional LLM explanation), optional **Loki** logs
> (`--profile logs`) and **Jaeger** tracing (`--profile tracing`).

# Monitoring, Observability and AI

A complete observability stack you can start with one command. It monitors a sample
app (request rate, errors, latency), the host and the containers, shows it in a
provisioned Grafana dashboard, and fires alerts through Alertmanager.

```
 loadgen ─► app :8080 ──/metrics──┐
            node-exporter :9100 ──┼─► Prometheus :9090 ──► Alertmanager :9093
            cAdvisor :8081 ───────┘        │
                                           └──► Grafana :3000 (dashboards as code)
```

## Run it

```bash
docker compose up -d
```

| Service | URL | Notes |
|---------|-----|-------|
| Grafana | http://localhost:3000 | admin / admin (set `GRAFANA_PASSWORD` to change); dashboard "App overview (RED)" is pre-loaded |
| Prometheus | http://localhost:9090 | Status → Targets, Alerts |
| Alertmanager | http://localhost:9093 | |
| App | http://localhost:8080 | `/`, `/health`, `/slow`, `/flaky`, `/metrics` |

The `loadgen` container sends continuous traffic, so graphs fill in within a minute.
`/flaky` fails ~30% of requests, so **HighErrorRate** fires after a few minutes.

Stop: `docker compose down` (add `-v` to delete stored data).

## What it demonstrates

- **RED method** (Rate, Errors, Duration) for services, plus host and container metrics (USE)
- Instrumenting an app with the Prometheus client: counters and histograms
- Scraping, alert rules with `for:` durations, severity labels, inhibition and grouping
- Dashboards and datasources **as code** (Grafana provisioning), nothing clicked by hand
- Percentile latency with `histogram_quantile`

## Useful PromQL

```promql
sum(rate(http_requests_total[1m]))                                      # throughput
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))  # error ratio
histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))  # p95
up == 0                                                                 # down targets
100 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100          # host CPU %
```

## Try an incident

```bash
docker compose stop app      # TargetDown fires after ~1 minute
docker compose start app     # alert resolves
```

## Notes

- The app image is the one built by the `03-github-actions-cicd` project; make the GHCR
  package public, or build it locally and edit the `image:` line.
- cAdvisor needs access to Docker internals and works best on Linux hosts. On Docker
  Desktop the container panels may be empty; the rest still works.
- The Alertmanager receiver is a placeholder. Add a Slack, email or PagerDuty config
  (instructions are in `alertmanager/alertmanager.yml`).

## Optional: logs and traces

```bash
docker compose --profile logs up -d       # Loki + Promtail; query in Grafana -> Explore -> Loki
docker compose --profile tracing up -d    # Jaeger UI at http://localhost:16686
```

## AI alert triage

```bash
python3 ai/alert_triage.py ai/sample_alerts.json                 # rule-based, no API key
pip install -r ai/requirements.txt
ANTHROPIC_API_KEY=... python3 ai/alert_triage.py ai/sample_alerts.json --llm
```

The triage is deterministic code. The LLM only explains it, and alert text is passed as
data inside delimiters so it cannot give the model instructions. Never commit API keys.
