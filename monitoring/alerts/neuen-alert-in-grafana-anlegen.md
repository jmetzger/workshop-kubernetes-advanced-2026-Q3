# Neuen Alert in Grafana anlegen und testen 

## Voraussetzung

  * ServiceMonitor eingerichtet: [Nginx mit ServiceMonitor anlegen](monitoring/praxis/03-nginx-servicemonitor.md)

## Basics 

  * am besten im über das jeweilige Panel im Dashboard (more -> new alert rule
  * Vorteil, die Query wird schon direkt übernommen

## Schritt 1: Neues Alert - Formular aufrufen

![image](https://github.com/user-attachments/assets/9e178aa0-2e4c-4f4d-8f18-6f5f5ca3d992)
 
  * Es wird immer zu einem Unified Alert 

## Schritt 2: Wichtig: Die Alert-Condition einstellen 

  * Diese ist aktuell falsch

![image](https://github.com/user-attachments/assets/2e09a392-686a-49e0-b56d-05afa586d54a)

  * So ist es richtig

![image](https://github.com/user-attachments/assets/b0a766a3-fbee-44a9-bb8a-a687710f7a06)


## Schritt 3: Preview alert rule condition 

   * Button klicken und gucken, wie es reagiert

![image](https://github.com/user-attachments/assets/4f471c7d-2cc5-4248-a2a4-1edaf1696a1d)


## Schritt 4: Ein oder mehrere Labels setzen und Folder erstellen 

  * Wir erstellen einen neunen Folder: app1 
  * Labels sind u.a. wichtig für die Benachrichtigung (Die erfolgen in Form von labels)
  * Wir nehmen hier

```
# label
team -> saas
```

## Schritt 6: Set evaluation behaviour 

  * Wie oft soll er überprüfen ? (das kann man nach Umgebung machen, z.B) 

![image](https://github.com/user-attachments/assets/9941383c-095c-44a2-95c2-6aa7c3256993)


## Schritt 7: Configure notifications 

### Contact Points 

  * Contact Point auswählen
  * In unserem Beispiel nehmen wir Slack

## Schritt 8: Save rule and exit 

  * Button oben rechts klicken

![image](https://github.com/user-attachments/assets/e0305e06-10a8-4cfb-8c6d-fc70cf629b4a)


## Schritt 9: Wo ist der Alert ?

  * alert rules -> app1 -> k8s-pod 

![image](https://github.com/user-attachments/assets/67644467-5b6d-4077-b961-9d89a736edf5)



## Schritt 10: Testen:

  * deployment löschen und im interface nachschauen 

```
cd
cd manifests
cd svc-nginx
```

```
kubectl -n web-demo get deploy nginx
```

```
nano 03-nginx-deployment-metrics.yaml
```

```
# Readiness Check, einbauen, der nicht funktioniert
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: web-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:stable
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-conf
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: default.conf
        readinessProbe:
          exec:
            command:
            - /bin/false
          initialDelaySeconds: 5
          periodSeconds: 10
      - name: exporter
        image: nginx/nginx-prometheus-exporter:latest
        args:
        - "-nginx.scrape-uri=http://localhost:80/stub_status"
        ports:
        - containerPort: 9113
      volumes:
      - name: nginx-conf
```


```

kubectl -n web-demo apply -f .
kubectl -n web-demo get pods 
```

