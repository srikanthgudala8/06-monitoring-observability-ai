# Interview notes: monitoring stack

## 60-second pitch

"I built an observability stack with Prometheus, Alertmanager and Grafana. The app is
instrumented with request counters and latency histograms; Prometheus scrapes it along
with node-exporter and cAdvisor. Alert rules cover availability, error rate, p95 latency
and host resources, and Grafana dashboards and datasources are provisioned from files so
the whole setup is reproducible."

## Concepts to be fluent in

- **Pull model:** Prometheus scrapes `/metrics` on a schedule; good for service discovery
  and knowing a target is down (`up == 0`). Short-lived jobs use the Pushgateway.
- **Metric types:** counter (only goes up, use `rate()`), gauge, histogram (buckets, used
  for percentiles), summary.
- **RED vs USE:** RED (Rate, Errors, Duration) for services; USE (Utilisation, Saturation,
  Errors) for resources like CPU and disks.
- **Golden signals:** latency, traffic, errors, saturation.
- **Why `rate()` over a range:** counters reset on restart; `rate` handles resets and gives per-second change.
- **Why `for:` on alerts:** avoids paging on brief spikes.
- **Alertmanager's job:** dedupe, group, route, silence and inhibit; Prometheus only evaluates rules.

## Likely questions

1. **Alert fatigue, how do you reduce it?** Alert on symptoms (user impact, SLOs), not
   causes; use `for:`, grouping, inhibition; every alert needs an action and a runbook.
2. **Explain p95 vs average latency.** Averages hide tail latency; p95/p99 show what the
   slowest users experience.
3. **Histogram vs summary?** Histograms are aggregatable across instances and quantiles
   are computed at query time; summaries compute quantiles client-side and can't be aggregated.
4. **How does Prometheus scale / store long-term data?** Local TSDB with retention; for
   long-term and HA use Thanos, Cortex/Mimir or remote write.
5. **Monitoring in Kubernetes?** Prometheus Operator / kube-prometheus-stack with
   ServiceMonitors and kube-state-metrics.
6. **Metrics vs logs vs traces?** Metrics: aggregated trends and alerts. Logs: detailed
   events. Traces: request path across services. Used together (Loki, Tempo, OpenTelemetry).
7. **What is an SLO / error budget?** Target reliability (e.g. 99.9% success); the budget is
   the allowed failure, used to balance releases against stability. Burn-rate alerts are the modern approach.
8. **How would you monitor something Prometheus can't scrape?** Write an exporter, use the
   Blackbox exporter for probes, or the Pushgateway for batch jobs.

## Honest limitations

Single Prometheus node (no HA), placeholder alert receiver, no log or trace pipeline.
Mention Loki/Tempo/OpenTelemetry as the natural next steps.
