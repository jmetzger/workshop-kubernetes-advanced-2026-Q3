# Uebung 1: Zugang zum bestehenden Cluster

## Hintergrund

Diese Uebung setzt voraus, dass der DOKS-Cluster `splunk-training` und der Bastion-Server
`client-splunk` bereits existieren (siehe `digitalocean/create-doks-cluster.sh` und
`digitalocean/create-bastion.sh`). Alle folgenden Schritte werden auf dem Bastion-Server
ausgefuehrt.

Bevor es losgeht, hier die Zielarchitektur, zu der die einzelnen Uebungen hinfuehren
(Details siehe [README](../README.md#architektur)): der Cluster enthaelt nur einen leichten
Log-Forwarder, Splunk selbst laeuft **extern** auf eigener Infrastruktur.

![Architektur: Splunk extern auf eigener VM](screenshots/05-architektur-variante-b.svg)

## Schritt 1: Auf dem Bastion einloggen

```
ssh -i ~/.ssh/id_ed25519_nopass root@client-splunk.do.t3isp.de
```

## Schritt 2: kubeconfig pruefen

Die kubeconfig liegt unter `/tmp/config` (vom Trainer per
`digitalocean/download-kubeconfig-to-bastion.sh` dorthin kopiert).

```
export KUBECONFIG=/tmp/config
kubectl get nodes
```

Erwartete Ausgabe: zwei Nodes im Status `Ready`.

## Schritt 3: KUBECONFIG dauerhaft setzen

```
echo 'export KUBECONFIG=/tmp/config' >> ~/.bashrc
source ~/.bashrc
kubectl cluster-info
```
