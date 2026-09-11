# Request Routing (Ambient-Mode)

## Prerequisites

  * Bookinfo im Ambient-Mode aufgesetzt ([04-install-demo-app.md](../../installation/ambient/04-install-demo-app.md))
  * Namespace `bookinfo` hat einen **Waypoint-Proxy** (`istio.io/use-waypoint=waypoint`)

## Hintergrund: Warum hier ein Waypoint nötig ist

  * Das HTTPRoute unten hängt (wie im Sidecar-Setup auch) direkt am Service (`parentRefs: kind: Service`, sog. "Mesh-Routing" / GAMMA) - kein eigenes Gateway nötig für diesen internen Traffic
  * Im Sidecar-Modus wertet der Envoy-Sidecar jedes Pods das HTTPRoute aus
  * Im Ambient-Modus kann `ztunnel` das NICHT - es arbeitet nur auf Layer 4 (TCP, mTLS) und kennt keine HTTP-Header. Header-basiertes Routing braucht deshalb zwingend den **Waypoint-Proxy** (Layer 7) im Namespace

## Schritt 1: Vorbereitung: Status review-pods

  * Status: alle Pods sind unter einem Service erreichbar

```
# Es gibt 3 verschieden review-pods (v1, v2, v3)
kubectl -n bookinfo get pods --show-labels | grep review
```

```
# Ein Service zeigt auf alle pods (Alle versionen der Review - Pods)
kubectl -n bookinfo get svc | grep reviews
```

## Schritt 2: Vorher (ohne request routing)

  * Es werden alle Pods angezeigt, die das Label: app:reviews haben
  * D.h. jedesmal wenn ich die Seite öffne, wird eine andere Version angegezeigt (v1, v2 oder v3) - es werden ganz normal die Services von Kubernetes verwendet
  * Service (selector: app:reviews)

```
kubectl -n bookinfo get svc reviews -o yaml
kubectl -n bookinfo get pods -l app=reviews --show-labels
```

```
# Gateway wurde in der Übung vorher angelegt
# du findest so die IP des gateways raus
kubectl -n bookinfo get svc bookinfo-gateway-istio
```

```
GATEWAY_URL=<external-ip-aus-der-vorigen-Ausgabe-eintragen>
```

```
# Im Browser mehrmals ausführen
# Im Block mit den Reviews wechselt die Version
$GATEWAY_URL/productpage
```

## Schritt 3: Übung (jetzt request - routing)

**Voraussetzung:**

- Bookinfo-App läuft bereits im Namespace `bookinfo` (Ambient + Waypoint)
- Service Reviews existiert
- Es gibt 3 verschieden Pods an Reviews (v1, v2 und v3)

### 0. Vorbereitung

```bash
mkdir -p ~/manifests/requests-ambient
cd ~/manifests/requests-ambient
```

### 1. HTTPRoute: Alle Requests → `reviews-v1`

```bash
cat <<EOF > ~/manifests/requests-ambient/httproute-reviews-v1.yaml
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

kubectl apply -f httproute-reviews-v1.yaml
kubectl -n bookinfo get httproute reviews
```

```
# Anzeige im Browser - es ist immer die v1 (keine Sterne)
http://$GATEWAY_URL/productpage
```

### 2. HTTPRoute anpassen: User `jason` → `reviews-v2`, Rest → `reviews-v1`

```bash
cat <<EOF > ~/manifests/requests-ambient/httproute-reviews-jason-v2.yaml
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
  - matches:
    - headers:
      - name: end-user
        value: jason
    backendRefs:
    - name: reviews-v2
      port: 9080
  - backendRefs:
    - name: reviews-v1
      port: 9080
EOF

kubectl apply -f httproute-reviews-jason-v2.yaml
kubectl -n bookinfo get httproute reviews -o yaml
```

### 3. Testen im Browser

```
echo "$GATEWAY_URL"

# 1. Im Browser: $GATEWAY_URL/productpage aufrufen (nicht eingeloggt oder anderer User)
#    → Reviews ohne Sterne (v1)

# 2. Im Browser: als User "jason" einloggen
#    → Reviews mit Sternen (v2)
```

### 4. Testen direkt gegen den Reviews-Service (ohne Browser-Login)

  * Der Header `end-user` wird sonst von `productpage` anhand des Login-Cookies gesetzt - für einen schnellen Test genügt ein Client-Pod im Mesh

```bash
kubectl -n bookinfo apply -f ~/istio/samples/sleep/sleep.yaml
kubectl -n bookinfo wait --for=condition=ready pod -l app=sleep --timeout=60s
```

```bash
# ohne Header -> reviews-v1 (keine "rating" im JSON)
kubectl -n bookinfo exec deploy/sleep -- curl -sS http://reviews:9080/reviews/0

# mit Header end-user: jason -> reviews-v2 (mit "rating"/Sternen)
kubectl -n bookinfo exec deploy/sleep -- curl -sS -H "end-user: jason" http://reviews:9080/reviews/0
```

## 5. Aufräumen

```bash
kubectl delete -f httproute-reviews-v1.yaml --ignore-not-found
kubectl delete -f httproute-reviews-jason-v2.yaml --ignore-not-found
```

## Reference:

  * https://istio.io/latest/docs/examples/bookinfo/#define-the-service-versions
  * https://istio.io/latest/docs/ambient/usage/l7-features/
