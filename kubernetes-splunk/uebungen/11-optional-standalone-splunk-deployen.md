# Uebung 11 (optional): Splunk Standalone (S1) deployen

> **Optionaler Anhang** - Fortsetzung von [Uebung 10](10-optional-splunk-operator-installieren.md).

## Hintergrund

Der `splunk/splunk-enterprise` Chart deployt ueber die Custom Resources des Operators eine
komplette Splunk-Topologie. Mit `sva.s1.enabled=true` wird nur eine einzelne
Standalone-Instanz angelegt (Splunk Validated Architecture "S1") - ausreichend fuer eine
Teststellung. Der Chart bringt per Default seinen eigenen Splunk-Operator als Dependency mit
(`splunk-operator.enabled: true`) - da wir den Operator in Uebung 10 schon separat installiert
haben, muss diese Dependency hier deaktiviert werden, sonst kollidieren beide Helm-Releases
bei der ServiceAccount-Ownership.

## Schritt 1: Splunk Enterprise (Standalone) installieren

```
helm install --set sva.s1.enabled=true --set splunk-operator.enabled=false splunk-enterprise-test splunk/splunk-enterprise -n splunk-operator
```

## Schritt 2: Rollout beobachten

Der Operator legt eine `Standalone` Custom Resource (Name `stdln`) und darueber ein
StatefulSet an. Das Hochfahren von Splunk Enterprise dauert einige Minuten (Ansible-Setup im
Container).

```
kubectl get standalone -n splunk-operator
kubectl get pods -n splunk-operator -w
```

Mit Strg+C abbrechen, sobald der Pod `splunk-stdln-standalone-0` im Status `Running`, `1/1` ist.

## Schritt 3: Status der Custom Resource pruefen

```
kubectl describe standalone -n splunk-operator
```

Erwartete Ausgabe: `phase: Ready` im Status-Abschnitt.

**Erwarteter Zwischenzustand:** kurz nach dem Start zeigt `kubectl get pods` den Pod im Status
`Init` oder `PodInitializing` - das ist normal, Splunk braucht ca. 3-5 Minuten zum Hochfahren.

Weiter mit [Uebung 12: Auf die Splunk-Web-UI zugreifen](12-optional-splunk-ui-zugriff-in-cluster.md).
