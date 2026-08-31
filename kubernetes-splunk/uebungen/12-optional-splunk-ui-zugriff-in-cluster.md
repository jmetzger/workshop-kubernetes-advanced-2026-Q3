# Uebung 12 (optional): Auf die Splunk-Web-UI zugreifen (In-Cluster-Variante)

> **Optionaler Anhang** - Fortsetzung von [Uebung 11](11-optional-standalone-splunk-deployen.md).
> Im Unterschied zur externen VM (Uebung 2, Schritt 5) gibt es hier keinen
> Reverse-Proxy mit oeffentlichem Zertifikat - der Zugriff laeuft ueber
> `kubectl port-forward` + SSH-Tunnel.

## Schritt 1: Admin-Passwort finden

Der Operator generiert beim ersten Start automatisch ein Secret mit dem Admin-Passwort.

```
kubectl get secrets -n splunk-operator | grep secret
```

## Schritt 2: Passwort auslesen

Das Secret zur Standalone-Instanz heisst `splunk-stdln-standalone-secret-v1`.

```
kubectl get secret splunk-stdln-standalone-secret-v1 -n splunk-operator -o jsonpath='{.data.password}' | base64 -d
echo
```

## Schritt 3: Port-Forward zur Web-UI

Diesen Befehl in einer eigenen Terminal-Session auf dem Bastion laufen lassen (blockiert):

```
kubectl port-forward -n splunk-operator splunk-stdln-standalone-0 8000:8000
```

## Schritt 4: Im Browser einloggen

Auf dem Bastion gibt es keine grafische Oberflaeche - dafuer in einer zweiten, lokalen
Terminal-Session per SSH-Tunnel zum eigenen Rechner weiterleiten:

```
ssh -i ~/.ssh/id_ed25519_nopass -L 8000:localhost:8000 root@client-splunk.do.t3isp.de
```

Dann im lokalen Browser `http://localhost:8000` oeffnen (kein HTTPS - die Splunk-Web-UI
laeuft in diesem Standalone-Deployment per Default auf HTTP, keine Zertifikatswarnung noetig).

Login: Benutzer `admin`, Passwort aus Schritt 2.

Weiter mit [Uebung 13: Log-Forwarding installieren](13-optional-log-forwarding-in-cluster.md).
