# Uebung 5: Aufraeumen

## Schritt 1: Forwarder und Demo-Namespace entfernen

```
kubectl delete namespace crashloop-demo
helm uninstall splunk-log-forwarder -n splunk-forwarder
kubectl delete namespace splunk-forwarder
```

## Schritt 2: Externe Splunk-VM abbauen

```
cd terraform-external-splunk
terraform destroy -var="do_token=$DO_TOKEN"
```

**Wichtig:** Das loescht die VM inkl. aller darauf indexierten Splunk-Daten unwiderruflich.
Vorher sichern, was noch gebraucht wird (z.B. per `splunk export` oder Screenshot der
Suchergebnisse).

## Schritt 3: Cluster und Bastion abbauen

Nur noetig, wenn auch der geteilte DOKS-Cluster/Bastion nicht mehr gebraucht wird - ausserhalb
des Bastions, vom Trainer-Rechner mit `DO_TOKEN` gesetzt:

```
doctl kubernetes cluster delete splunk-training
doctl compute droplet delete client-splunk
```

**Wichtig:** Das loescht den DOKS-Cluster und den Bastion-Server unwiderruflich inkl. aller
darauf laufenden Daten.

## Optional: Splunk im Cluster betreiben

Wurde zusaetzlich die optionale In-Cluster-Variante (Uebungen 10-14) durchgespielt, deren
Ressourcen ebenfalls entfernen - siehe
[Uebung 14: Aufraeumen (In-Cluster-Variante)](14-optional-aufraeumen-in-cluster.md).
