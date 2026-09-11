# Install with istioctl (Ambient-Mode)

  * Genau wie im Sidecar-Modus die einfachste Installationsart
  * Statt einem Envoy-Sidecar pro Pod: ein `ztunnel`-Agent pro Node (Layer 4) + optional Waypoint-Proxies pro Namespace (Layer 7)
  * `istioctl install --set profile=ambient` installiert automatisch: Istio-Core, Istiod, das Istio-CNI-Plugin UND ztunnel (alles in einem Schritt)

## Unterschied zum Helm-Weg

  * Mit Helm installiert man `base`, `istiod`, `cni` und `ztunnel` als vier einzelne Charts (siehe [03-install-with-helm.md](03-install-with-helm.md))
  * Mit istioctl reicht ein Kommando

## Schritt 1: istio runterladen und installieren

  * Falls schon aus der Sidecar-Installation vorhanden, kann dieser Schritt übersprungen werden - istioctl kann beide Profile

```
cd
# aktuelle stabile Version ist 1.31.0 (Stand 2026-09)
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.31.0 sh -
ln -s ~/istio-1.31.0 ~/istio
echo "export PATH=~/istio-1.31.0/bin:$PATH" >> ~/.bashrc
source ~/.bashrc
```

> [!TIP]
> Istio empfiehlt, dass `istioctl` (Client) exakt dieselbe Version wie die Control-Plane (`istiod`) hat - "using matching versions helps avoid unforeseen issues". Prüfen mit `istioctl version` (zeigt Client-, Control-Plane- und Data-Plane-Version).

## Schritt 2: Installation mit dem Ambient-Profil

```
istioctl install --set profile=ambient --skip-confirmation
```

> [!CAUTION]
> Wenn hier eine Warnung kommt: `detected Calico CNI with 'bpfConnectTimeLoadBalancing=TCP'; this must be set to 'Disabled'` - siehe Schritt 3, VOR dem weiteren Testen fixen.

**Erwartetes Ergebnis:**

```
kubectl get pods -n istio-system
```

  * `istio-cni-node-*` (DaemonSet, ein Pod pro Node)
  * `istiod-*`
  * `ztunnel-*` (DaemonSet, ein Pod pro Node)
  * KEIN `istio-ingressgateway` - das brauchen wir nicht, wir nutzen die Kubernetes Gateway API

## Schritt 3: Calico-Fix (nur bei Calico-CNI-Clustern nötig)

**Warum das nötig ist (einfach erklärt):** Calico klinkt sich mit dem Feature "Connect-Time Load Balancing" (CTLB) schon beim `connect()`-Aufruf einer Anwendung ein und schreibt die Ziel-IP direkt um (z.B. Service-IP -> Pod-IP), bevor das Paket überhaupt losgeschickt wird. Istio Ambient braucht aber das unveränderte Paket, um es per iptables/eBPF zum `ztunnel` umzuleiten (dort passiert mTLS + Routing). Schreibt Calico die Ziel-IP vorher schon um, sieht `ztunnel` die Verbindung nicht mehr richtig - die Ambient-Umleitung greift dann nicht zuverlässig, oft ohne sichtbaren Fehler. Deshalb muss dieses eine Calico-Feature abgeschaltet werden (der Rest von Calico - Networking, NetworkPolicies - bleibt unangetastet).

```
kubectl patch felixconfiguration default --type merge \
  -p '{"spec":{"bpfConnectTimeLoadBalancing":"Disabled"}}'

# Kontrolle
kubectl get felixconfiguration default -o jsonpath='{.spec.bpfConnectTimeLoadBalancing}{"\n"}'
```

Erwartete Ausgabe: `Disabled`

## Schritt 4: Gateway API CRD's installieren

```
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.2/standard-install.yaml
```

## Reference: Get started

  * https://istio.io/latest/docs/ambient/getting-started/
