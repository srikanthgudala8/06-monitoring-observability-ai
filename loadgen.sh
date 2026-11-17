#!/bin/sh
# Generates a steady mix of traffic so the dashboards have data.
while true; do
  curl -s -o /dev/null http://app:8080/
  curl -s -o /dev/null http://app:8080/health
  curl -s -o /dev/null http://app:8080/slow
  curl -s -o /dev/null http://app:8080/flaky
  sleep 0.5
done
