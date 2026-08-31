# Verschiedene Image-Versionen ausliefern 

## Ausgangssituation

  * v1 hat kein Bild
  * v2 hat ein Bild (url)

## Ziel, das ganz soll seperat deployed werden (d.h. nicht jeder soll es sehen) 

## Schritt 1: 2. Version ausrollen 

```
kubectl apply -f services/catalog/kubernetes/catalog-deployment-v2.yaml 
kubectl get pods  --show-labels 
```

## Schritt 2: Testen 

```
# Das sie gleiche am gleichen Server hängen, werden sie "teilweise" abwechselnd
# angezeigt
while true; do curl -v http://jochen.istio.t3isp.de/api/catalog; sleep .5; done
```

## Schritt 3: DestinationRule - 2 verschiedene Versionen bekannt machen 

  * Wir legen fest, dass es 2 verschiedene Versionen gibt, die unterschiedliche Label tragen

```
cat ingress-virtualservice/catalog-destinationrule.yaml
kubectl apply -f ingress-virtualservice/catalog-destinationrule.yaml 
# here we can also see a version label 
kubectl get pods --show-labels 
```

## Schritt 4: Route all traffic to v1 

```
cat ingress-virtualservice/catalog-virtualservice-all-v1.yaml
kubectl apply -f ingress-virtualservice/catalog-virtualservice-all-v1.yaml
```

```
# Now we only see v1 responses -> no image
while true; do curl -v http://jochen.istio.t3isp.de/api/catalog; sleep .5; done
```

## Schritt 5: Now we route it to another service if there is a specific header 

```
cat ingress-virtualservice/catalog-virtualservice-dark-v2.yaml
kubectl apply -f ingress-virtualservice/catalog-virtualservice-dark-v2.yaml
```

```
# Let's test
# We also get version with image 
curl -H "x-dark-launch: v2" http://jochen.istio.t3isp.de/api/catalog
```
