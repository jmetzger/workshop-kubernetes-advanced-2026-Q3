# Demo - App Installation (Ambient / Waypoint Proxy)

## Überblick

<img width="693" height="465" alt="image" src="https://github.com/user-attachments/assets/22cbf386-5a90-458b-8157-51620ef829ea" />

## Vorbereitung

  * Statt `istio-injection=enabled` (Sidecar) gibt es im Ambient-Mode das Label `istio.io/dataplane-mode=ambient` - Pods bekommen dadurch KEINEN Sidecar, sondern werden transparent über den `ztunnel`-Agent des Nodes geroutet (Layer 4, mTLS)

```
kubectl create ns bookinfo
kubectl label namespace bookinfo istio.io/dataplane-mode=ambient
```

## Waypoint Proxy ausrollen

  * Der Waypoint ist die Ambient-Entsprechung des Sidecars für alles, was Layer 7 braucht (HTTP-Routing, JWT/RBAC-Policies, Retries, ...) - `ztunnel` allein kann nur Layer 4

```
cd
mkdir -p manifests/waypoint
cd manifests/waypoint
```

```
# YAML generieren (dry-run)
istioctl waypoint generate --namespace bookinfo --for all > waypoint.yaml
```

```
# Anschauen was passiert
cat waypoint.yaml
```

```
# Ausrollen
kubectl apply -f waypoint.yaml
kubectl label namespace bookinfo istio.io/use-waypoint=waypoint
```

```
# Überprüfen
kubectl -n bookinfo get gateways
istioctl waypoint list --namespace bookinfo
```

Erwartetes Ergebnis: `PROGRAMMED=True` (kann ein paar Sekunden dauern)

## Optional: Falls hier ~/istio - Ordner noch nicht existiert 

```
cd 
# current version of istio is 1.31.0
curl -L https://istio.io/downloadIstio | sh -
ln -s ~/istio-1.31.0 ~/istio
```

## bookinfo App ausrollen

```
kubectl -n bookinfo apply -f ~/istio/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl -n bookinfo apply -f ~/istio/samples/bookinfo/platform/kube/bookinfo-versions.yaml
kubectl -n bookinfo get pods
```

**Erwartetes Ergebnis:** `READY 1/1` bei allen Pods (kein Sidecar, anders als bei der Installation mit dem demo-Profil, wo `2/2` erwartet wird)

## testen ob die app funktioniert

```
kubectl -n bookinfo exec deployments/ratings-v1 -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
```

## App mit gateway api nach aussen öffnen

```
# That's what we do ....
cat  ~/istio/samples/bookinfo/gateway-api/bookinfo-gateway.yaml
```

```
kubectl -n bookinfo apply -f ~/istio/samples/bookinfo/gateway-api/bookinfo-gateway.yaml
kubectl -n bookinfo get gateways
kubectl -n bookinfo get httproutes -o yaml
```

```
# note the external-ip from this output
# gateway automatically creates a service
kubectl -n bookinfo get svc bookinfo-gateway-istio
```

```
http://<external-ip>/productpage
# or in your browser
```

## Reference

  * https://istio.io/latest/docs/ambient/getting-started/deploy-sample-app/
