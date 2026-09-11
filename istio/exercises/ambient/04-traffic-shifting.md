# Traffic Shifting (Ambient-Mode)

  * Schrittweise Umleitung von Netzwerk-Traffic zwischen zwei Service-Versionen
  * Voraussetzung wie bei [Request Routing](02-exercise-request-routing.md): Bookinfo im Ambient-Mode + Waypoint-Proxy im Namespace `bookinfo` (Layer 7 für HTTPRoute-Gewichtung)

### 0. Vorbereitung

```bash
mkdir -p ~/manifests/traffic-shifting-ambient
cd ~/manifests/traffic-shifting-ambient
```

### 1. 100% Traffic -> reviews.v1

```
cat <<'EOF' > ~/manifests/traffic-shifting-ambient/route-reviews-v1.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
  namespace: bookinfo
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
EOF
```

```
kubectl apply -n bookinfo -f route-reviews-v1.yaml
kubectl get httproute -n bookinfo reviews -o yaml | less
```

### 2. Testen

```
# Seite öffnen
http://<deine-ip>/productpage

# Egal wie oft du die Seite lädst, es bleibt immer v1
```

Direkt gegen den Service (schneller, ohne Browser):

```bash
kubectl -n bookinfo apply -f ~/istio/samples/sleep/sleep.yaml
kubectl -n bookinfo wait --for=condition=ready pod -l app=sleep --timeout=60s

for i in $(seq 1 5); do
  kubectl -n bookinfo exec deploy/sleep -- curl -sS http://reviews:9080/reviews/0 | grep -o '"podname": "[a-z0-9-]*"'
done
```

### 3. 50% (v1) /50% (v3) Traffic

```
cat <<'EOF' > ~/manifests/traffic-shifting-ambient/route-reviews-50-50.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
  namespace: bookinfo
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
      weight: 50
    - name: reviews-v3
      port: 9080
      weight: 50
EOF
```

```bash
kubectl apply -n bookinfo -f route-reviews-50-50.yaml
kubectl get httproute -n bookinfo reviews -o yaml | head -n 40
```

## 4. Testen

```
# Seite öffnen
http://<deine-ip>/productpage

# Abwechselnd bei mehrmals laden v1 (keine Sterne) und v3 (sterne)
```

```bash
for i in $(seq 1 10); do
  kubectl -n bookinfo exec deploy/sleep -- curl -sS http://reviews:9080/reviews/0 | grep -o '"podname": "[a-z0-9-]*"'
done
```

Erwartetes Ergebnis: gemischt v1/v3, über 10 Requests ungefähr 50/50 verteilt.

## 5. 100% auf v3

```
cat <<'EOF' > ~/manifests/traffic-shifting-ambient/route-reviews-v3.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
  namespace: bookinfo
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v3
      port: 9080
EOF
```

```
kubectl apply -n bookinfo -f route-reviews-v3.yaml
kubectl get httproute -n bookinfo reviews -o yaml | head -n 50
```

```
# Seite öffnen
http://<deine-ip>/productpage

# bei mehrmals laden immer v3
```

### 6. Aufräumen

```
kubectl delete -n bookinfo httproute reviews --ignore-not-found
```

## Reference:

 * https://istio.io/latest/docs/tasks/traffic-management/traffic-shifting/
 * https://istio.io/latest/docs/ambient/usage/l7-features/
