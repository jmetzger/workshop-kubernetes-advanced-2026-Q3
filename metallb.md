# Metallb 

## General 

  * Supports bgp and arp (l2 mode) - this exercise uses l2/arp
  * Divided into controller (ipam), speaker (advertises the ip)

## Installation Ways  

  * helm 
  * manifests 

## Step 1: install metallb

```
# We use L2 mode (arp), not bgp
# The speaker is required in both modes - it is the component that
# actually announces the IP on the network (controller only does IPAM)

helm repo add metallb https://metallb.github.io/metallb 
```

```
# reset-values, always reset values on upgrade 
helm upgrade --install metallb metallb/metallb --namespace=metallb-system --create-namespace --version 0.15.2 --reset-values
```

## Step 2: addresspool

```
# find your node public ips first - "kubectl get nodes -o wide" does NOT
# show them (no cloud-controller-manager here), EXTERNAL-IP stays <none>.
# they are listed in ~/cluster-zugang.txt on client-bka.
cat ~/cluster-zugang.txt
```

```
cd
mkdir -p manifests
cd manifests
mkdir lb
cd lb
nano 01-addresspool.yml 
```

```
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  # hier die ip-adressen Deiner 3 worker nodes eintragen
  - 157.230.113.124/32
```

```
kubectl apply -f .
```

## Step 3: L2Advertisement

```
nano 02-advertisement.yml
```

```
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
```

```
kubectl apply -f .
```

## Step 4: Test do i get an external ip 

```
nano 03-deploy.yml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: web-nginx
  replicas: 3
  template:
    metadata:
      labels:
        run: web-nginx
    spec:
      containers:
      - name: cont-nginx
        image: nginx
        ports:
        - containerPort: 80

```


```
nano 04-service.yml
```

```
apiVersion: v1
kind: Service
metadata:
  name: svc-nginx
  labels:
    svc: nginx
spec:
  type: LoadBalancer
  ports:
  - port: 80
    protocol: TCP
  selector:
    run: web-nginx
```


```
kubectl apply -f .
kubectl get pods
kubectl get svc
```

```
# auf dem client 
curl http://<ip aus get svc>
```

```
kubectl delete -f 03-deploy.yml 04-service.yml 
```

## Step 5: Referenz:

  * https://metallb.io/installation/#installation-with-helm
