# Tracen mit Jaeger 

## Schritt 1: Dashboard starten 

```
# 1x durch den Trainer reicht hier
istioctl dashboard jaeger --browser=false

# Tunnel in ssh aufbauen
source Port: 16686 
Destination: localhost:16686
```

## Schritt 2: Jaeger öffnen 

```
# ssh tunnel aufbauen - portwarding

# Im Browser:
http://localhost:16686
```

## Schritt 3: Daten einsehen 

```
# Links Deinen Service auswählen
# Ganz unten -> Find Traces anklicken
# Oben einen Punkt anklicken
```

