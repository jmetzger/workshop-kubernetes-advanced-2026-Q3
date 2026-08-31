# 500er produzieren 

## Schritt 1: Chaos script starten 

```
cd istio-exercises 
cd bin 
# Produce 500er 100% of the time 
./chaos.sh 500 100
```

## Schritt 2: Abfrage mit curl wieder durchführen 

```
# Wir bekommen einen 500er 
curl -v http://jochen.istio.t3isp.de/api/catalog
```

## Schritt 3: Jetzt nur 50% der Zeit einen Fehler produzieren 

```
./chaos.sh 500 50
# und testen 
while true; do curl -v http://jochen.istio.t3isp.de/api/catalog; sleep .5; done
```

## Schritt 4: Den VirtualService einen retry machen lassen 

```
# 2s timeout 3x wiederholen 
# retries:
#   attempts: 3
#   perTryTimeout: 2s 
kubectl apply -f ingress-virtualservice/catalog-virtualservice.yaml 
```

```
# Jetzt haben wir bessere Ergebnisse
while true; do curl -v http://jochen.istio.t3isp.de/api/catalog; sleep .5; done
```

## Schritt 5: Wieder Ausgangszustand herstellen 

```
./chaos.sh 500 delete 
```
