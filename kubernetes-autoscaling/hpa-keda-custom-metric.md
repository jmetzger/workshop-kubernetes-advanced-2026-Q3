# HPA mit eigener Metrik statt CPU (KEDA + Prometheus)

## Hintergrund

  * Der HorizontalPodAutoscaler (HPA) kennt von Haus aus nur die Kubernetes-Metrics-APIs:
    `metrics.k8s.io` (CPU/Memory, ueber den metrics-server), `custom.metrics.k8s.io` und
    `external.metrics.k8s.io`. Er kann NIE direkt PromQL gegen Prometheus sprechen.
  * Fuer eine eigene (Business-/App-)Metrik braucht es einen Adapter, der zwischen
    Prometheus und dieser Metrics-API uebersetzt. Zwei Wege:
    * **Prometheus Adapter** - klassisch, aber fummelige Rule-Konfiguration
    * **KEDA** (Kubernetes-based Event-Driven Autoscaling, CNCF-Projekt) - du definierst
      ein einfaches `ScaledObject` mit einer PromQL-Query, KEDA fragt Prometheus selbst ab
      und erzeugt/pflegt automatisch ein ganz normales HPA im Hintergrund
  * Wir verwenden KEDA. Als Beispiel-Metrik nehmen wir die **Worker-Auslastung eines
    PHP-FPM-Pools** (aktive / gesamt Worker in %) - ein typisches App-Level-Signal, das
    CPU-Auslastung nicht zeigen wuerde (ein Worker kann voll ausgelastet sein, obwohl er
    nur auf eine langsame Datenbank wartet und dabei kaum CPU braucht).

## Voraussetzung

  * Keine - diese Uebung bringt ihren eigenen, schlanken Prometheus mit (Schritt 2, im
    Namespace `scaling-monitoring`) und braucht NICHT den vollen kube-prometheus-stack aus
    "Monitoring mit Prometheus" (Tag 2, Namespace `monitoring`, mit
    Grafana/Traefik-Ingress/Letsencrypt/basic-auth). Deshalb passt sie hier unter
    Workload-Skalierung, direkt nach der normalen HPA-Uebung.

## Schritt 1: KEDA installieren

```
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm upgrade --install keda kedacore/keda --namespace keda --create-namespace
```

```
kubectl -n keda get pods
# 3 Pods sollten Running sein (operator, operator-metrics-apiserver, admission-webhooks)
```

## Schritt 2: Eigenen, schlanken Prometheus installieren

  * Nur fuer diese Uebung gedacht - ohne Grafana, ohne Ingress/TLS/basic-auth (das kommt
    erst mit dem vollen Setup auf Tag 2). Reicht, damit KEDA intern PromQL-Queries
    stellen kann.
  * Bewusst ein **eigener Namespace `scaling-monitoring`**, getrennt vom Namespace
    `monitoring`, den Tag 2 fuer den vollen Stack (Grafana, Ingress, ...) nutzt - keine
    Vermischung der beiden Installationen.

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace scaling-monitoring --create-namespace --version 72.3.0 \
  --set grafana.enabled=false \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
```

```
kubectl -n scaling-monitoring get pods
# Warten, bis u.a. prometheus-prometheus-kube-prometheus-prometheus-0 Running/Ready ist
```

## Schritt 3: Vorbereitung

```
cd
mkdir -p manifests
cd manifests
mkdir php-fpm-hpa
cd php-fpm-hpa
```

## Schritt 4: Namespace

```
# vi 01-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: php-fpm-demo
```

```
kubectl apply -f 01-namespace.yaml
```

## Schritt 5: Die App - ConfigMap mit PHP-Skript, FPM-Pool und nginx-Config

  * `sleep(5)` simuliert eine "teure" Anfrage (z.B. langsamer DB-Call), die einen
    PHP-FPM-Worker fuer 5 Sekunden blockiert
  * `pm = static` + `pm.max_children = 3` -> der Pool hat IMMER genau 3 Worker (bewusst
    klein gehalten, damit sich die Uebung schnell in eine Ueberlastsituation bringen laesst)
  * `pm.status_path = /status` aktiviert die eingebaute FPM-Statusseite

```
# vi 02-app-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: php-fpm-app
  namespace: php-fpm-demo
data:
  index.php: |
    <?php
    // Simuliert eine "teure" Anfrage, die einen PHP-FPM-Worker
    // fuer 5 Sekunden blockiert (z.B. langsamer DB-Call, PDF-Export, ...)
    sleep(5);
    echo "OK - Worker war 5 Sekunden belegt\n";
  zz-status.conf: |
    ; Achtung: pm.status_path liefert NUR Zahlen des eigenen Pools.
    ; Ein zweiter, dedizierter "Status-Pool" (mit eigenem Port) wuerde
    ; sich nur selbst vermessen - nicht den Workload-Pool "www". Deshalb
    ; bleibt der Status-Endpoint bewusst im selben Pool wie die Worker.
    [www]
    pm = static
    pm.max_children = 3
    pm.status_path = /status
  default.conf: |
    server {
      listen 80;
      root /var/www/html;
      index index.php;

      location / {
        try_files $uri $uri/ /index.php$is_args$args;
      }

      location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
      }
    }
```

```
kubectl apply -f 02-app-configmap.yaml
```

  * **Hinweis (warum das oben wichtig ist):** Wenn alle 3 Worker mit der 5-Sekunden-Anfrage
    beschaeftigt sind, muss sich auch die Status-Abfrage selbst in dieselbe Warteschlange
    einreihen - sie teilt sich den Pool mit dem Workload. Bei extremer Ueberlast (z.B. 10+
    parallele Anfragen gegen nur 3 Worker) kann das dazu fuehren, dass Prometheus den
    Scrape-Timeout reisst und die Metrik zeitweise fehlt. Deshalb erzeugen wir in Schritt 10
    bewusst nur moderate Ueberlast (8 parallele Requests gegen 3 Worker) - genug zum
    Skalieren, aber die Status-Abfrage kommt trotzdem noch durch.

## Schritt 6: Deployment (3 Container: php-fpm, nginx, Exporter) + Service

  * `nginx` reicht `.php`-Requests per FastCGI an `php-fpm` weiter (Port 9000, localhost)
  * `exporter` (`hipages/php-fpm_exporter`) fragt die FPM-Statusseite ab und wandelt sie
    in Prometheus-Metriken um (`phpfpm_active_processes`, `phpfpm_total_processes`, ...)

```
# vi 03-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-fpm-app
  namespace: php-fpm-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: php-fpm-app
  template:
    metadata:
      labels:
        app: php-fpm-app
    spec:
      containers:
      - name: php-fpm
        image: php:8.3-fpm
        volumeMounts:
        - name: app
          mountPath: /var/www/html/index.php
          subPath: index.php
        - name: app
          mountPath: /usr/local/etc/php-fpm.d/zz-status.conf
          subPath: zz-status.conf
        resources:
          requests:
            cpu: 50m
          limits:
            cpu: 200m
      - name: nginx
        image: nginx:stable
        ports:
        - containerPort: 80
        volumeMounts:
        - name: app
          mountPath: /var/www/html/index.php
          subPath: index.php
        - name: app
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: default.conf
      - name: exporter
        image: hipages/php-fpm_exporter:2.2.0
        args:
        - "server"
        - "--phpfpm.scrape-uri=tcp://127.0.0.1:9000/status"
        ports:
        - containerPort: 9253
      volumes:
      - name: app
        configMap:
          name: php-fpm-app
---
apiVersion: v1
kind: Service
metadata:
  name: php-fpm-app
  namespace: php-fpm-demo
  labels:
    app: php-fpm-app
spec:
  selector:
    app: php-fpm-app
  ports:
  - name: http
    port: 80
    targetPort: 80
  - name: metrics
    port: 9253
    targetPort: 9253
```

```
kubectl apply -f 03-deployment.yaml
kubectl -n php-fpm-demo rollout status deployment/php-fpm-app
```

## Schritt 7: Exporter-Metriken pruefen

```
kubectl -n php-fpm-demo run test-metrics --image=busybox:1.36 --restart=Never --rm -i --command -- wget -qO- http://php-fpm-app.php-fpm-demo:9253/metrics
```

```
# Erwartete Ausgabe (Ausschnitt):
phpfpm_active_processes{pool="www",...} 0
phpfpm_idle_processes{pool="www",...} 3
phpfpm_total_processes{pool="www",...} 3
```

## Schritt 8: ServiceMonitor

```
# vi 04-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: php-fpm-app
  namespace: php-fpm-demo
  labels:
    release: prometheus  # muss zu Helm-Werten passen!
spec:
  selector:
    matchLabels:
      app: php-fpm-app
  namespaceSelector:
    matchNames:
    - php-fpm-demo
  endpoints:
  - port: metrics
    path: /metrics
    interval: 15s
    scrapeTimeout: 10s
```

```
kubectl apply -f 04-servicemonitor.yaml
```

  * **Warum das hier noetig ist:** KEDA fragt im naechsten Schritt NICHT unsere App direkt,
    sondern schickt seine PromQL-Query an den Prometheus-Server. Damit dort ueberhaupt
    etwas steht, muss Prometheus unsere Metrik vorher eingesammelt haben - genau das
    erledigt dieser ServiceMonitor (er sagt Prometheus: "scrape den Exporter alle 15s").
    Ohne ihn liefe KEDAs Query ins Leere.

```
# Ist der Target in Prometheus gruen? Kein Ingress fuer diesen schlanken
# Stack (siehe Schritt 2) - deshalb per Port-Forward pruefen:
kubectl -n scaling-monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090
```

```
# In einem zweiten Terminal (oder Browser):
http://localhost:9090/targets
# suchen nach: php-fpm-demo/php-fpm-app/0
```

## Schritt 9: ScaledObject (KEDA) - die eigentliche Skalierungslogik

  * Statt `%CPU` nehmen wir hier `avg(active) / avg(total) * 100` - die Worker-Auslastung
    in Prozent, ueber alle Pods gemittelt. Genau dasselbe Muster wie bei der CPU-HPA-Uebung
    (Ziel-Prozentwert), nur mit einer App-eigenen Kennzahl statt einer Infra-Kennzahl.
  * `pollingInterval`/`cooldownPeriod` lassen wir bewusst weg - die sind nur relevant,
    wenn `minReplicaCount` (oder `idleReplicaCount`) auf 0 steht (Scale-to-Zero).

```
# vi 05-scaledobject.yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: php-fpm-app
  namespace: php-fpm-demo
spec:
  scaleTargetRef:
    name: php-fpm-app
  minReplicaCount: 1
  maxReplicaCount: 5
  triggers:
  - type: prometheus
    metadata:
      # serverAddress zeigt auf Prometheus, NICHT auf unsere App/den Exporter!
      # KEDA fragt hier den Prometheus-Server per PromQL ab (die Daten dafuer
      # hat der ServiceMonitor aus Schritt 8 vorher dort hineingescraped).
      # Der grosse Vorteil: avg(...) aggregiert automatisch ueber ALLE Pods -
      # ein einzelner Pod koennte seine eigene Auslastung kennen, aber nicht,
      # wie ausgelastet das gesamte Deployment gerade ist.
      serverAddress: http://prometheus-kube-prometheus-prometheus.scaling-monitoring.svc.cluster.local:9090
      query: avg(phpfpm_active_processes{namespace="php-fpm-demo"}) / avg(phpfpm_total_processes{namespace="php-fpm-demo"}) * 100
      threshold: "70"
```

```
kubectl apply -f 05-scaledobject.yaml
```

```
# KEDA erzeugt jetzt automatisch ein HPA im Hintergrund:
kubectl -n php-fpm-demo get scaledobject
kubectl -n php-fpm-demo get hpa

# NAME                   REFERENCE                TARGETS      MINPODS   MAXPODS   REPLICAS   AGE
# keda-hpa-php-fpm-app   Deployment/php-fpm-app   0/70 (avg)   1         5         1          15s
```

## Schritt 10: Last erzeugen und Skalierung beobachten

  * 8 parallele Dauerschleifen gegen einen Pool mit nur 3 Workern - reicht zum
    Ueberschreiten der 70%-Schwelle, ohne die Status-Abfrage zu blockieren (siehe Hinweis
    oben bei Schritt 5)

```
# vi 06-load-generator.yaml
apiVersion: v1
kind: Pod
metadata:
  name: load-generator
  namespace: php-fpm-demo
spec:
  restartPolicy: Never
  containers:
  - name: load-generator
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      for i in $(seq 1 8); do
        (while true; do wget -q -O- http://php-fpm-app.php-fpm-demo >/dev/null; done) &
      done
      wait
```

```
kubectl apply -f 06-load-generator.yaml
```

```
# In einem zweiten Terminal beobachten:
kubectl -n php-fpm-demo get hpa keda-hpa-php-fpm-app --watch
```

```
# So in etwa laeuft es (Beispiel aus dem Test):
# NAME                   REFERENCE                TARGETS           MINPODS   MAXPODS   REPLICAS   AGE
# keda-hpa-php-fpm-app   Deployment/php-fpm-app   41667m/70 (avg)   1         5         1          28m
# keda-hpa-php-fpm-app   Deployment/php-fpm-app   83333m/70 (avg)   1         5         1          28m   <- ueber 70% -> skaliert
# keda-hpa-php-fpm-app   Deployment/php-fpm-app   50/70 (avg)       1         5         2          29m   <- 2 Pods, Last verteilt sich
```

```
kubectl -n php-fpm-demo get deployment php-fpm-app
# READY sollte jetzt 2/2 zeigen (oder mehr, je nach Last)
```

## Schritt 11: Last stoppen und Scale-down beobachten

```
kubectl -n php-fpm-demo delete pod load-generator
kubectl -n php-fpm-demo get hpa keda-hpa-php-fpm-app --watch
```

  * Der Zielwert faellt sofort unter 70%, die Anzahl der Replicas bleibt aber laut Standard-HPA-
    Verhalten noch ein paar Minuten stehen (Stabilization-Window, standardmaessig 5 Minuten),
    bevor auf 1 Replica zurueckskaliert wird - das verhindert staendiges Hoch-/Runterschaukeln
    bei schwankender Last.

## Aufraeumen

```
kubectl delete ns php-fpm-demo
kubectl delete ns scaling-monitoring
helm -n keda uninstall keda
kubectl delete ns keda
```

## Ref

  * https://keda.sh/docs/latest/concepts/scaling-deployments/
  * https://keda.sh/docs/latest/scalers/prometheus/
  * https://github.com/hipages/php-fpm_exporter
  * https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/#autoscaling-on-more-specific-metrics
