# Uebung: CNI-Provider Calico installieren

## Hintergrund

  * Dein Cluster wurde bewusst OHNE CNI-Plugin provisioniert (nur kubeadm init/join)
  * Ohne CNI: Nodes bleiben `NotReady`, CoreDNS bleibt `Pending` - es koennen
    keine normalen Pods starten
  * Genau das schauen wir uns erst an, dann beheben wir es

## Schritt 1: Ausgangslage ansehen (kaputt by design)

```
kubectl get nodes
# STATUS: NotReady - warum?

kubectl describe node <dein-cp-node> | grep -A 3 "Ready "
# message: Network plugin returns error: cni plugin not initialized

kubectl -n kube-system get pods
# coredns: Pending (kein CNI -> kein Pod-Netz -> nicht schedulebar)
```

## Schritt 2: Tigera-Operator installieren

  * Wichtig: `kubectl create` (nicht `apply`) - die Manifeste sind zu gross
    fuer die apply-Annotation

```
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.2/manifests/tigera-operator.yaml
```

```
# Operator laeuft?
kubectl -n tigera-operator get pods
```

## Schritt 3: Calico-Konfiguration (Custom Resources) anlegen

  * Die `Installation`-Resource sagt dem Operator, wie er Calico ausrollen soll
  * Das Default-Pod-Netz darin (192.168.0.0/16) passt zu unserem
    kubeadm-Setup (`--pod-network-cidr=192.168.0.0/16`)

```
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.2/manifests/custom-resources.yaml
```

## Schritt 4: Zuschauen, wie das Cluster "heile" wird

```
# 1-3 Minuten, bis alles laeuft
kubectl -n calico-system get pods -w
# Ctrl+C wenn calico-node auf allen Nodes Running ist
```

```
kubectl -n calico-system get pods
kubectl get nodes
# STATUS: Ready !

kubectl -n kube-system get pods
# coredns: Running
```

## Schritt 5: Funktionstest - jetzt starten auch normale Pods

```
kubectl run cni-test --image=nginx
kubectl get pods -o wide
# Running, mit IP aus 192.168.x.x
```

## Aufraeumen

  * Calico bleibt natuerlich installiert - nur den Test-Pod entfernen:

```
kubectl delete pod cni-test
```

## Reference

  * https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart
