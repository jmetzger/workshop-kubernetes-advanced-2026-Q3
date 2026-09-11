# Übung: Workload ins Ambient-Mesh aufnehmen (statt Sidecar-Injection)

  * Im Sidecar-Modus wird pro Pod ein Envoy-Container injiziert (`istioctl kube-inject`, `READY 2/2`)
  * Im Ambient-Modus gibt es KEINE Injection - ein Namespace-Label reicht, der Pod bleibt `READY 1/1`
  * Die Umleitung zum `ztunnel`-Agent des Nodes passiert transparent über das Istio-CNI-Plugin (kein Init-Container/Sidecar im Pod sichtbar)

## 1. Verzeichnis anlegen

```bash
cd
mkdir -p ~/manifests/nginx-ambient
```

## 2. Nginx-Deployment erstellen (Namespace direkt mit Ambient-Label)

```bash
cat <<'EOF' > ~/manifests/nginx-ambient/nginx.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nginx-ambient
  labels:
    istio.io/dataplane-mode: ambient
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: nginx-ambient
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: nginx-ambient
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
EOF
```

## 3. Anwenden (KEIN kube-inject nötig)

```bash
kubectl apply -f ~/manifests/nginx-ambient/nginx.yaml
```

## 4. Aufnahme ins Mesh prüfen

```bash
kubectl get pods -n nginx-ambient
```

Erwartetes Ergebnis: `READY 1/1` - kein zweiter Container, obwohl der Namespace im Mesh ist.

```bash
istioctl ztunnel-config workload -n istio-system | grep nginx-ambient
```

Erwartetes Ergebnis: Der Pod taucht mit Protokoll `HBONE` auf (vom `ztunnel` erfasst) und `WAYPOINT=None` (nur Layer 4, da kein Waypoint für diesen Namespace deployt wurde).

```
NAMESPACE       POD NAME                                                ADDRESS        NODE         WAYPOINT PROTOCOL
nginx-ambient   nginx-xxxxxxxxxx-xxxxx                                  <pod-ip>       <node>       None     HBONE
```

## Zusammenfassung

| | Sidecar | Ambient |
|---|---|---|
| Aktivierung | `istio-injection=enabled` + Injection (Webhook/`kube-inject`) | `istio.io/dataplane-mode=ambient` (Label reicht) |
| Sichtbar im Pod | zusätzlicher Container `istio-proxy` (`READY 2/2`) | kein zusätzlicher Container (`READY 1/1`) |
| Nachweis der Aufnahme | `kubectl get pods` | `istioctl ztunnel-config workload` |
| Layer 7 (HTTP-Routing, Policies) | immer vorhanden (Envoy pro Pod) | erst mit zusätzlichem Waypoint-Proxy pro Namespace |
