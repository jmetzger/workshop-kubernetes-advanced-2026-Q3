# Debug (Ambient-Mode)

## Why like this ?

  * Kein `istio-proxy`-Sidecar mehr im Pod (anders als im Sidecar-Modus) - ein Debug-Container läuft aber trotzdem im gleichen Pod-Netzwerk-Namespace und sieht damit denselben (durch `ztunnel` umgeleiteten) Traffic
  * Zusätzlich gibt es Ambient-spezifische Debug-Kommandos, um zu prüfen, ob/wie ein Workload vom Mesh erfasst wird

## Variante 1: Debug-Container zum Debuggen

  * Debug Container in productpage - pod starten, um Verbindung zu pod -> Review zu debuggen

```
kubectl -n bookinfo get pods | grep productpage
# diesen entsprechend hier verwenden
kubectl -n bookinfo debug productpage-v1-54bb874995-rr7cv -it --image=busybox
```

```
# in der bash
wget -O - http://reviews:9080/reviews/1
```

```
exit
```

**Erwartetes Ergebnis:** Die Antwort kommt trotz `READY 1/1` (kein Sidecar) korrekt zurück - `ztunnel` leitet den Traffic transparent über das Istio-CNI-Plugin um.

## V2 - Eigener Pod - Podtester

```
kubectl -n bookinfo run --rm -it podtester --image=busybox --overrides='{ "spec": { "serviceAccount": "bookinfo-productpage" }  }'
```

## V3 - Ambient-Aufnahme prüfen (istioctl ztunnel-config)

  * Zeigt an, welcher `ztunnel`-Pod (auf welchem Node) einen Workload erfasst hat und ob ein Waypoint zwischengeschaltet ist

```
istioctl ztunnel-config workload -n istio-system | grep bookinfo
```

  * Spalte `WAYPOINT`: `waypoint` = Layer 7 aktiv (HTTP-Routing/Policies möglich), `None` = nur Layer 4 (mTLS, aber kein HTTP-Verständnis)
  * Spalte `PROTOCOL`: `HBONE` = über den Ambient-Tunnel geroutet, `TCP` = nicht vom Mesh erfasst (z.B. das Gateway selbst)

## V4 - Ztunnel-Logs eines konkreten Nodes ansehen

```
NODE=$(kubectl -n bookinfo get pod -l app=productpage -o jsonpath='{.items[0].spec.nodeName}')
ZPOD=$(kubectl -n istio-system get pod -l app=ztunnel --field-selector spec.nodeName=$NODE -o jsonpath='{.items[0].metadata.name}')
echo "node=$NODE ztunnel=$ZPOD"

istioctl ztunnel-config log $ZPOD.istio-system
```

## V5 - Waypoint-Proxy wie einen normalen Envoy debuggen

  * Der Waypoint ist ein ganz normaler Envoy-Proxy - die klassischen `istioctl proxy-config`-Kommandos funktionieren genauso

```
WAYPOINT_POD=$(kubectl -n bookinfo get pod -l gateway.networking.k8s.io/gateway-name=waypoint -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config routes $WAYPOINT_POD.bookinfo
```

## Reference

  * https://istio.io/latest/docs/ambient/usage/observability/
