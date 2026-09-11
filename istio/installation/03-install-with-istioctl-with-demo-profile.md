# Install with istioctl 

  * Most simplistic way
  * Doing the right setup is done with profiles
  * Interestingly it uses an compile-in helm chart  (see also: Show what a profile does)

## Hint for production 

  * Best option (in most cases) is default 

## in our case: Including demo (tracing is activated) 

  * Not suitable for production !!

## Show what a profile does 

```
istioctl manifest generate > istio-manifest.yaml
# If not profile is mentioned, it uses the default profile
# it does not use an operator 
cat istio-manifest.yaml | grep -i -A20 "^Kind" | less
# If you want you can apply it like so:
# kubectl apply -f istio-manifest.yaml 

```

## Installation including Demo 

> [!CAUTION]
> This profile (demo) enables high levels of tracing and access logging so it is not suitable for performance tests.

### Schritt 1: istio runterladen und installieren 

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

### Schritt 2: bash completion integrieren 

```
cp ~/istio/tools/istioctl.bash ~/istioctl.bash
echo "source ~/istioctl.bash" >> ~/.bashrc
source ~/istioctl.bash
```

### Schritt 2.5. See what it would install 

```
# dry-run 
istioctl install -f ~/istio/samples/bookinfo/demo-profile-no-gateways.yaml -y --dry-run
```

### Schritt 3: Installation with demo (by using operator)

```
# cat ~/istio/samples/bookinfo/demo-profile-no-gateways.yaml
# Wird vom ControlPlane ausgewertet
# Hier wird das ingressgateway abgeschaltet,
# Weil wir das nicht benötigen, wenn wir
# die Kubernetes Gateway API verwenden 
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: demo
  components:
    ingressGateways:
    - name: istio-ingressgateway
      enabled: false
    egressGateways:
    - name: istio-egressgateway
      enabled: false
```


```
# Der Trend geht Richtung Kubernetees Gateway API
istioctl install -f ~/istio/samples/bookinfo/demo-profile-no-gateways.yaml -y
```

### Schritt 4: Gateway API's CRD's installieren 

```
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.2/standard-install.yaml
```

## Reference: Get started 

  * https://istio.io/latest/docs/setup/getting-started/
