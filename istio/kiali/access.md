# Access kiali (when client is on a jump server without browser)

## Auf dem Jump-Server Port-Forwarding aktivieren 

```
istioctl dashboard kiali --help
# Every body needs to set his own local port - we will us your tln - number, e.g.
# tln1  -> --port=20001
# tln2  -> --port=20002
# tln19 -> --port=20019
# e.g. for tln2
istioctl dashboard kiali -p 20002 --browser=false

# or: if you want to it with port-forward directly
# 20001 will be that port on server (that will be the same for all of you

kubectl -n istio-system port-forward svc/kiali 20002:20001
```

## Vom Lokalen - Rechner  

### Variante A 

```
Erklärung:
o Im Brower geben wir http://localhost:20002 ein.
o Dies wird durch ssh geleitet
o auf der anderen Seite auf dem Server geht es dann weiter zu
  localhost:20002
o Wenn man auf dem Jump-Server lsof -i macht, sieht man folgendes:

<- das ist die Verbindung auf die wir gehen.
istioctl 670550 tln1    9u  IPv4 10284211      0t0  TCP *:20002 (LISTEN)
```

```
# The same for all trainees 
# Lokal port 20001
# @ip of our jump-server
# ssh -L <port-of-service>:<ip-of-jump-server>:<local-port-see-list> tlnX@<ip of jump server>
ssh -L 20002:localhost:20002 tlnX@165.227.173.22
```

```
# Im lokalen Browser öffnen
http://localhost:20002
```

### Variante B 

```
Für Putty Nutzer (zusätzlich zum ganz normalen Einrichten des Servers)
Unter SSH Tunnels gehen, Source Port: 20002, Destination: 165.227.173.22:20002
Auf Add klicken
```

```
# Im lokalen Browser öffnen 
http://localhost:20002
```
