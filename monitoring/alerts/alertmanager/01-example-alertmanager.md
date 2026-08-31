# Example alert manager 

## Steps 1:

```
cd
mkdir -p manifests
cd manifests
mkdir alertrule
cd alertrule
```

```
nano 01-rule.yaml
```

```
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: always-firing-alert
  namespace: monitoring
  labels:
    release: prometheus 
    role: alert-rules
spec:
  groups:
  - name: test.rules
    rules:
    - alert: AlwaysFiring
      expr: vector(1)
      for: 10s
      labels:
        severity: info
      annotations:
        summary: "This alert always fires"
        description: "This is a test alert that always triggers (expr: vector(1))"
```

```
kubectl apply -f .
```

## Beanchrichtung nach Webhook 

```
alertmanager:
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 1m
      repeat_interval: 1h
      receiver: 'test-receiver'
    receivers:
    - name: 'test-receiver'
      webhook_configs:
      - url: 'http://example.com/'
```
