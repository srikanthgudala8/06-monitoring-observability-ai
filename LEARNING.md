# Phase 6 - Monitoring, Observability and AI Basics (Days 50-60)

**Goal:** know how to tell whether a system is healthy, find out why it is not, and use AI
as a practical tool for DevOps work (without trusting it blindly).

**Setup:** Docker and Docker Compose. Everything runs from this repo:
`docker compose up -d` (metrics), add `--profile logs` for Loki, `--profile tracing` for Jaeger.

---

## Day-by-day plan

### Day 50 - Observability concepts
- **Learn:** monitoring vs observability, the three pillars (metrics, logs, traces), golden signals (latency, traffic, errors, saturation), RED and USE methods, SLI / SLO / error budget.
- **Lab:** pick your Phase 2 app and write down 3 SLIs and a target SLO for each (e.g. "99.5% of requests succeed over 30 days").
- **Server link:** list what you would watch on a Linux web server (CPU, memory, disk, request rate, error rate, latency) and sort each into metric, log or trace.
- **Done when:** you can explain an error budget to a manager.

### Day 51 - Prometheus and PromQL
- **Learn:** pull model, scrape configs, targets, metric types (counter, gauge, histogram), labels, `rate()`, `sum by`, `histogram_quantile`.
- **Lab:** `docker compose up -d`, open Prometheus at :9090, Status -> Targets. Run each query from the README and explain the result.
- **Done when:** you can write a query for request rate, error ratio and p95 latency without looking.

### Day 52 - Grafana dashboards
- **Learn:** data sources, panels, variables, provisioning (dashboards as code), dashboard design (answer a question per panel).
- **Lab:** open "App overview (RED)" in Grafana (:3000, admin/admin). Add a panel for in-flight CPU saturation, a stat panel for availability, and a dashboard variable for `endpoint`. Export the JSON into `grafana/dashboards/`.
- **Done when:** your changes survive `docker compose down && up` because they are in Git.

### Day 53 - Alerting
- **Learn:** alert rules, `for:`, severities, Alertmanager routing, grouping, inhibition, silences, symptom-based alerts, runbooks.
- **Lab:** read `prometheus/alert_rules.yml`. Stop the app (`docker compose stop app`), watch **TargetDown** go pending then firing, find it in Alertmanager. Add a Slack or Teams webhook receiver. Write a runbook (`runbooks/target-down.md`) for it.
- **Done when:** every alert has an owner, an action and a runbook.

### Day 54 - Logs
- **Learn:** structured (JSON) logs, centralised logging, Loki + LogQL, Azure Log Analytics (KQL) and CloudWatch Logs Insights, log levels, correlation IDs.
- **Lab:** `docker compose --profile logs up -d`. In Grafana -> Explore -> Loki: `{container="..."} |= "error"`, then `rate({container=~".+app.+"}[1m])`. Compare the same question in KQL: `ContainerLog | where LogEntry contains "error"`.
- **Done when:** you can go from a firing alert to the matching log lines in under a minute.

### Day 55 - Tracing and OpenTelemetry
- **Learn:** spans, traces, context propagation, OpenTelemetry as the vendor-neutral standard, sampling.
- **Lab:** `docker compose --profile tracing up -d`. In a venv install `opentelemetry-distro opentelemetry-exporter-otlp`, run `opentelemetry-bootstrap -a install`, then start the app with
  `OTEL_SERVICE_NAME=demo-app OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 opentelemetry-instrument python app/app.py`.
  Send a few requests and look at the traces in Jaeger (:16686).
- **Done when:** you can describe how a trace helps when logs and metrics are not enough.

### Day 56 - AI fundamentals
- **Learn:** machine learning vs deep learning vs generative AI, what an LLM is (predicts the next token), tokens and context window, training vs inference, temperature, hallucinations, embeddings (meaning as numbers), RAG (retrieval augmented generation), fine-tuning vs prompting, privacy and data-handling.
- **Lab:** use an AI assistant on a real task (explain a Terraform error, review a Dockerfile). For each answer, verify it against official docs and write down what was wrong or missing.
- **Done when:** you can explain why an LLM can sound confident and still be wrong.

### Day 57 - Using an LLM from Python
- **Learn:** API keys and secrets (never commit them), messages, system vs user prompts, `max_tokens`, cost per token, rate limits, retries, structured output (ask for JSON and validate it).
- **Lab:** `pip install -r ai/requirements.txt`, set `ANTHROPIC_API_KEY`, run `python3 ai/alert_triage.py ai/sample_alerts.json --llm`. Read `ask_llm()` and `build_prompt()` carefully.
- **Done when:** you understand each parameter in the API call and what it costs.

### Day 58 - AI for DevOps (practical and safe)
- **Learn:** good uses (summarise incidents and logs, draft runbooks and postmortems, explain unfamiliar configs, generate first-draft IaC and tests) and risky uses (running generated commands blindly, pasting secrets or customer data, trusting made-up flags or APIs). Prompt injection: log lines and tickets are untrusted input.
- **Lab:** extend `ai/alert_triage.py`: add a `--postmortem` flag that asks the model for a draft postmortem (timeline, impact, root cause hypotheses, follow-ups). Keep the rule-based output as the source of truth and label AI text clearly.
- **Rule of thumb:** deterministic code decides; AI explains and drafts; a human approves.
- **Done when:** you have a short written policy for how you would use AI on a team.

### Day 59 - Capstone: observe the whole platform
Bring the phases together:
1. Deploy the app (Phase 2 image) to your kind cluster from Phase 5.
2. Install `kube-prometheus-stack` with Helm and add a `ServiceMonitor` for the app (it exposes `/metrics`).
3. Import or adapt the RED dashboard; add an SLO panel.
4. Create an alert and trigger it on purpose (`/flaky`). Write the runbook.
5. Add a GitHub Actions job that validates alert rules with `promtool`.
6. Record a 3-minute demo: break it, detect it, find the cause with metrics, logs and traces, fix it.

### Day 60 - Polish and portfolio
Finish the roadmap repo checklist: READMEs with diagrams, badges, clean commits, pinned repos,
resume bullets, LinkedIn update, and two full mock interviews (see `devops-roadmap-60-days`).

---

## Useful PromQL / KQL / LogQL
```promql
sum(rate(http_requests_total[1m]))                                     # traffic
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))   # error ratio
histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))   # p95
1 - (sum(rate(http_requests_total{status!~"5.."}[30d])) / sum(rate(http_requests_total[30d])))  # error budget burned
```
```kusto
AzureDiagnostics | where Category == "x" | summarize count() by bin(TimeGenerated, 5m)
Heartbeat | summarize LastSeen = max(TimeGenerated) by Computer   // servers that stopped reporting
```
```logql
{container="app"} |= "error" != "health"
sum by (container) (rate({container=~".+"}[5m]))
```

## Check yourself
1. Metrics vs logs vs traces: what question does each answer best?
2. Why alert on symptoms instead of causes?
3. What is an SLO and how does an error budget guide decisions?
4. Counter vs gauge vs histogram?
5. Why use `rate()` and not the raw counter?
6. What is an LLM hallucination and how do you protect against it?
7. What is prompt injection and why does it matter for tools that read logs or tickets?
8. How would you use AI safely in an incident without leaking data?
