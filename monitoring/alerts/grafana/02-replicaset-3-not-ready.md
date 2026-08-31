# Alerting 3 pods not ready 

Hier ist ein vollständiges Beispiel für ein Kubernetes Deployment mit **absichtlich fehlschlagender Readiness-Probe**, das du nutzen kannst, um **Alerting zu testen**, wenn mindestens 3 Pods nicht "ready" sind:

---

## 📄 Beispiel-Deployment `unready-demo.yaml`

```
mkdir manifests
cd manifests
mkdir unready
cd unready
```

```
nano unready-demo.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: unready-demo
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: unready-demo
  template:
    metadata:
      labels:
        app: unready-demo
    spec:
      containers:
        - name: demo
          image: busybox
          command: ["sh", "-c", "sleep 3600"]
          readinessProbe:
            exec:
              command:
                - /bin/false
            initialDelaySeconds: 5
            periodSeconds: 10
```

```
kubectl apply -f .
```

---

### 🔍 Erklärung:

* **`sleep 3600`**: Der Container läuft eigentlich stabil.
* **`/bin/false`** in der Readiness-Probe sorgt dafür, dass Kubernetes den Pod **niemals als „ready“** einstuft.
* Du kannst über `kube_pod_status_ready{condition="false"}` abfragen, wie viele Pods als „not ready“ gelten.

---

### 🧪 Test-Query für Alert in Grafana / Prometheus:

```promql
sum(kube_pod_status_ready{namespace="default", condition="false", pod=~"unready-demo-.*"}) >= 3
```

> ⚠️ Achte darauf, dass `kube-state-metrics` in deinem Cluster läuft und `kube_pod_status_ready` bereitstellt.

---

### ✅ So nutzt du es:

1. YAML-Datei anwenden:

   ```bash
   kubectl apply -f unready-demo.yaml
   ```

2. Abfragen:

   ```bash
   kubectl get pods -l app=unready-demo
   ```

   Du wirst sehen, dass alle Pods im Status `0/1 Ready` sind.

3. **Grafana-Alert konfigurieren** auf Basis der obigen Query.

```


```
sum(kube_pod_status_ready{namespace="dein-namespace", condition="false", pod=~"dein-deployment-.*"}) >= 3
```


---

Möchtest du auch ein **komplettes Beispiel für den passenden Grafana Alert** (als YAML oder UI-Anleitung)?
