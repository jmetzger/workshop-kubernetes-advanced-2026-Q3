# Feste IP aus Pool beziehen (metallb)

## Beispiel

```
cd manifests/lb
```

```
# bestehende 04-service.yml aus der metallb-Uebung anpassen (NICHT neu anlegen,
# sonst kollidiert der Service-Name svc-nginx mit zwei Manifests im selben Ordner)
nano 04-service.yml
```

```
apiVersion: v1
kind: Service
metadata:
  name: svc-nginx
  labels:
    svc: nginx
  annotations:
    # spec.loadBalancerIP ist deprecated (seit 1.24) - MetalLB nutzt stattdessen
    # diese Annotation, eure ip aus dem pool nehmen
    metallb.io/loadBalancerIPs: 167.99.130.85
spec:
  type: LoadBalancer
  ports:
  - port: 80
    protocol: TCP
  selector:
    run: web-nginx
```

```
kubectl apply -f 04-service.yml
# ist es die von oben ?
kubectl get svc
```
