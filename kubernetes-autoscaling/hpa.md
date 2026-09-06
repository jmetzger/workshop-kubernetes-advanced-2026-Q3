# HorizonalPodAutoscaler - Example 

## Aufbau 

```
# Aufbau des Containers 
ROM php:5-apache
COPY index.php /var/www/html/index.php
RUN chmod a+rx index.php
This code defines a simple index.php page that performs some CPU intensive computations, in order to simulate load in your cluster.

<?php
  $x = 0.0001;
  for ($i = 0; $i <= 1000000; $i++) {
    $x += sqrt($x);
  }
  echo "OK!";
?>
```

## Schritt 1: Metrics-Server installieren (Voraussetzung)

  * Der HorizontalPodAutoscaler braucht die Metrics API (metrics-server), um die CPU-Auslastung der Pods auszulesen.
  * Auf unseren kubeadm-Trainingsclustern ist der metrics-server NICHT vorinstalliert.
  * Ohne ihn zeigt `kubectl get hpa` beim TARGET dauerhaft `<unknown>` und es wird nie skaliert.

```
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
```

```
cd
mkdir -p helm-charts/metrics-server
cd helm-charts/metrics-server
nano values.yml
```

```
# Die kubelets im Trainingscluster nutzen selbst-signierte Zertifikate,
# daher braucht der metrics-server dieses Flag
args:
  - --kubelet-insecure-tls
```

```
helm -n kube-system upgrade --install metrics-server metrics-server/metrics-server --version 3.13.0 -f values.yml
```

```
# Pruefen - dauert ca. 1 Minute, bis der Pod Ready ist
kubectl -n kube-system get pods | grep metrics-server
```

```
# Sobald er Ready ist, liefert die Metrics API Daten:
kubectl top nodes
kubectl top pods -A
```

## Walkthrough 

```
# vi 01-php-apache-deploy.yml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  selector:
    matchLabels:
      run: php-apache
  replicas: 1
  template:
    metadata:
      labels:
        run: php-apache
    spec:
      containers:
      - name: php-apache
        image: k8s.gcr.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
  labels:
    run: php-apache
spec:
  ports:
  - port: 80
  selector:
    run: php-apache


```


```
kubectl apply -f 01-php-apache-deploy.yml 
```


```
# autoscaler erstellen
# (--cpu-percent=50 ist deprecated, aktuelle Syntax:)
kubectl autoscale deployment php-apache --cpu=50% --min=1 --max=10
kubectl get hpa 
kubectl get hpa -o yaml 

# Output
##NAME         REFERENCE                     TARGET    MINPODS   MAXPODS   REPLICAS   AGE
## php-apache   Deployment/php-apache/scale   0% / 50%  1         10        1  

```

```
# Last erhöhen 
# Run this in a separate terminal
# so that the load generation continues and you can carry on with the rest of the steps
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"

# type Ctrl+C to end the watch when you're ready
kubectl get hpa php-apache --watch
# Nach ca. 1 Minute geht die Last hoch 

# NAME         REFERENCE                     TARGET      MINPODS   MAXPODS   REPLICAS   AGE
# php-apache   Deployment/php-apache/scale   305% / 50%  1         10        1          3m

# Und etwas später noch mehr 

# NAME         REFERENCE                     TARGET      MINPODS   MAXPODS   REPLICAS   AGE
# php-apache   Deployment/php-apache/scale   305% / 50%  1         10        7  

```

```
# Wie sieht es aus ?
kubectl get deployment php-apache
# You should see the replica count matching the figure from the HorizontalPodAutoscaler

NAME         READY   UP-TO-DATE   AVAILABLE   AGE
php-apache   7/7      7           7           19m
```

## Ref:

  * https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/ 
