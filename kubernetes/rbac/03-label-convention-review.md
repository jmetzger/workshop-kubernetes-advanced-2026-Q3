# RBAC-Hygiene: Label-Konvention pruefen und Nutzung im Audit-Log nachweisen

Getestet gegen Kubernetes 1.37 (kubeadm, eigenes Cluster).

Die [Uebung zu Least Privilege](../rbac-create-user-kubernetes-1-25.md) zeigt, wie man
overprivilegierte ServiceAccounts findet. Diese Uebung geht einen Schritt weiter:
Kubernetes speichert nirgends, wann eine Role, ClusterRole oder ein RoleBinding
zuletzt tatsaechlich benutzt wurde - kein Feld, keine API. Wir bauen deshalb eine
Label-Konvention (`owner`, `purpose`, `review-by`), pruefen sie automatisiert, und
zeigen anschliessend, wie man ueber das Audit-Log des kube-apiserver einen echten
Nutzungsnachweis bekommt - und wo dessen Grenzen liegen.

## Voraussetzungen

- Eigenes kubeadm-Cluster mit `kubectl`-Zugriff (Cluster-Admin-Kubeconfig)
- `jq` installiert

## Ueberblick

```
Schritt 1: Namespace vorbereiten
Schritt 2: Drei ServiceAccounts + RoleBindings anlegen (gepflegt / unbeschriftet / abgelaufen)
Schritt 3: Audit-Query 1 - fehlende Pflicht-Labels finden
Schritt 4: Audit-Query 2 - abgelaufene review-by-Termine finden
Schritt 5: Audit-Log am kube-apiserver aktivieren
Schritt 6: Echten Zugriff erzeugen und im Audit-Log nachweisen
Schritt 7: Gegenprobe - unbenutzte Bindung im Audit-Log nicht nachweisbar
Schritt 8: Aufraeumen
```

---

## Schritt 1: Namespace vorbereiten

```
kubectl create namespace rbac-hygiene
```

## Schritt 2: Drei RBAC-Identitaeten anlegen

Ein sauber gepflegter ServiceAccount (`owner`, `purpose`, `review-by` in der Zukunft),
ein komplett unbeschrifteter (Gegenbeispiel), und einer mit abgelaufenem `review-by`:

```
# vi 01-rbac-hygiene.yml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: rbac-hygiene
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ci-deploy-payment-api
  namespace: rbac-hygiene
  labels:
    owner: team-payment
    purpose: ci-deploy-payment-api
    review-by: "2026-12-09"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ci-deploy-payment-api-binding
  namespace: rbac-hygiene
  labels:
    owner: team-payment
    purpose: ci-deploy-payment-api
    review-by: "2026-12-09"
subjects:
- kind: ServiceAccount
  name: ci-deploy-payment-api
  namespace: rbac-hygiene
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: batch-job-alt
  namespace: rbac-hygiene
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: batch-job-alt-binding
  namespace: rbac-hygiene
subjects:
- kind: ServiceAccount
  name: batch-job-alt
  namespace: rbac-hygiene
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: legacy-export
  namespace: rbac-hygiene
  labels:
    owner: team-data
    purpose: nightly-export-legacy-crm
    review-by: "2026-08-11"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: legacy-export-binding
  namespace: rbac-hygiene
  labels:
    owner: team-data
    purpose: nightly-export-legacy-crm
    review-by: "2026-08-11"
subjects:
- kind: ServiceAccount
  name: legacy-export
  namespace: rbac-hygiene
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

```
kubectl apply -f 01-rbac-hygiene.yml
```

`ci-deploy-payment-api` ist der Normalfall: klarer Owner, klarer Zweck, ein Termin
in der Zukunft, an dem jemand pruefen muss, ob es das noch braucht. `batch-job-alt`
ist der haeufigste Fall in echten Clustern: irgendwann angelegt, nie beschriftet.
`legacy-export` ist beschriftet, aber der Review-Termin ist laengst verstrichen -
niemand hat reagiert.

## Schritt 3: Fehlende Pflicht-Labels finden

```
kubectl get serviceaccounts,rolebindings -n rbac-hygiene -o json | jq -r '
  .items[] |
  select(.metadata.name != "default") |
  select((.metadata.labels.owner == null) or (.metadata.labels.purpose == null) or (.metadata.labels["review-by"] == null)) |
  "\(.kind)/\(.metadata.name): fehlende Pflicht-Labels"
'
```

**Erwartete Ausgabe:**

```
ServiceAccount/batch-job-alt: fehlende Pflicht-Labels
RoleBinding/batch-job-alt-binding: fehlende Pflicht-Labels
```

## Schritt 4: Abgelaufene review-by-Termine finden

```
kubectl get serviceaccounts,rolebindings -n rbac-hygiene -o json | jq -r --arg today "$(date +%F)" '
  .items[] |
  select(.metadata.labels["review-by"] != null) |
  select(.metadata.labels["review-by"] < $today) |
  "\(.kind)/\(.metadata.name): review-by \(.metadata.labels["review-by"]) liegt in der Vergangenheit"
'
```

**Erwartete Ausgabe:**

```
ServiceAccount/legacy-export: review-by 2026-08-11 liegt in der Vergangenheit
RoleBinding/legacy-export-binding: review-by 2026-08-11 liegt in der Vergangenheit
```

**Wichtig:** Diese beiden Queries pruefen nur, ob die Konvention eingehalten wird
und ob ein Review faellig ist - nicht, ob die Berechtigung tatsaechlich noch
gebraucht wird. Das kann Kubernetes ohne Weiteres gar nicht beantworten. Genau das
zeigen die naechsten Schritte.

---

## Schritt 5: Audit-Log am kube-apiserver aktivieren

Echte Nutzungsdaten liefert ausschliesslich das Audit-Log des kube-apiserver -
nicht Kubelet- oder Anwendungs-Logs. Auf einem kubeadm-Cluster ist der
kube-apiserver ein Static Pod, dessen Manifest direkt auf dem Control-Plane-Node
liegt. Wir editieren es ueber `kubectl debug node` - kein SSH-Zugriff auf den Node
noetig, nur die Cluster-Admin-Kubeconfig:

```
CP_NODE=$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')
kubectl debug node/$CP_NODE -it --image=alpine:3.20 --profile=general -- chroot /host sh
```

Im Node-Shell (`chroot /host`):

```
cp /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/kube-apiserver.yaml.orig
mkdir -p /var/log/kubernetes/audit

cat > /etc/kubernetes/audit-policy.yaml <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
EOF

sed -i '/--authorization-mode=Node,RBAC/a\    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml\n    - --audit-log-path=/var/log/kubernetes/audit/audit.log\n    - --audit-log-maxage=1\n    - --audit-log-maxbackup=1' /etc/kubernetes/manifests/kube-apiserver.yaml

sed -i '/^  hostNetwork: true/i\    - mountPath: /etc/kubernetes/audit-policy.yaml\n      name: audit-policy\n      readOnly: true\n    - mountPath: /var/log/kubernetes/audit\n      name: audit-log' /etc/kubernetes/manifests/kube-apiserver.yaml

sed -i '/^status: {}/i\  - hostPath:\n      path: /etc/kubernetes/audit-policy.yaml\n      type: File\n    name: audit-policy\n  - hostPath:\n      path: /var/log/kubernetes/audit\n      type: DirectoryOrCreate\n    name: audit-log' /etc/kubernetes/manifests/kube-apiserver.yaml

exit
```

Der Kubelet erkennt die Manifest-Aenderung und startet den kube-apiserver-Pod neu.
**`kubectl` haengt dabei fuer ca. 30-60 Sekunden** (`connection refused`) - das ist
erwartet, kein Fehler. Warten und erneut versuchen:

```
kubectl get nodes
```

Sobald die Nodeliste wieder kommt, laeuft der apiserver mit Audit-Log.

## Schritt 6: Echten Zugriff erzeugen und nachweisen

Wir tun so, als waere `ci-deploy-payment-api` ein Pod, der ueber seinen
ServiceAccount-Token auf Pods zugreift:

```
kubectl get pods -n rbac-hygiene --as=system:serviceaccount:rbac-hygiene:ci-deploy-payment-api
```

Jetzt im Audit-Log nachsehen, ob und wodurch dieser Zugriff erlaubt wurde:

```
CP_NODE=$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')
kubectl debug node/$CP_NODE --image=alpine:3.20 --profile=general -- chroot /host sh -c \
  'grep ci-deploy-payment-api-binding /var/log/kubernetes/audit/audit.log | tail -1'
```

**Erwartete Ausgabe (Auszug):**

```
"authorization.k8s.io/reason":"RBAC: allowed by RoleBinding \"ci-deploy-payment-api-binding/rbac-hygiene\" of Role \"pod-reader\" to ServiceAccount \"ci-deploy-payment-api/rbac-hygiene\""
```

Das ist der einzige Weg, mit dem Kubernetes selbst belegt: Diese Bindung wurde
tatsaechlich gezogen, nicht nur vergeben. Der RBAC-Authorizer schreibt bei jeder
erlaubten Anfrage genau diese `authorization.k8s.io/reason`-Annotation.

## Schritt 7: Gegenprobe - keine Nutzung nachweisbar

```
CP_NODE=$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')
kubectl debug node/$CP_NODE --image=alpine:3.20 --profile=general -- chroot /host sh -c \
  'grep -c legacy-export-binding /var/log/kubernetes/audit/audit.log'
```

**Erwartete Ausgabe:**

```
0
```

`legacy-export-binding` taucht im Audit-Log nicht auf - seit das Log laeuft, hat
niemand darueber zugegriffen. Das ist ein starkes Indiz, aber **kein Beweis**: Es
belegt nur den beobachteten Zeitraum. Ein Quartalsjob, der einmal alle drei Monate
laeuft, waere im Log genauso unsichtbar, obwohl er gebraucht wird. Deshalb bleibt
die Entscheidung am `review-by`-Termin: abgelaufenes Label + keine Spur im
Audit-Log seit der letzten Pruefung = starker Kandidat zum Loeschen, kein
Automatismus.

---

## Schritt 8: Aufraeumen

Audit-Log-Konfiguration wieder vom Node entfernen (sonst waechst die Datei
unbegrenzt weiter):

```
CP_NODE=$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')
kubectl debug node/$CP_NODE -it --image=alpine:3.20 --profile=general -- chroot /host sh
```

Im Node-Shell (die Sicherung aus Schritt 5 zurueckspielen, statt die Aenderungen
einzeln per sed zu suchen):

```
cp /etc/kubernetes/kube-apiserver.yaml.orig /etc/kubernetes/manifests/kube-apiserver.yaml
rm -f /etc/kubernetes/kube-apiserver.yaml.orig /etc/kubernetes/audit-policy.yaml
rm -rf /var/log/kubernetes/audit
exit
```

Namespace loeschen:

```
kubectl delete namespace rbac-hygiene
```

---

## Zusammenfassung

| Frage | Beantwortet durch | Beweist |
|---|---|---|
| Sind Owner/Zweck/Review-Termin gepflegt? | Label-Query (Schritt 3) | Compliance mit der Konvention |
| Ist ein Review faellig? | review-by-Query (Schritt 4) | Faelligkeit, nicht Nutzung |
| Wurde die Berechtigung tatsaechlich gezogen? | Audit-Log-Reason (Schritt 6) | Echte Nutzung im beobachteten Zeitraum |
| Wird sie nicht mehr gebraucht? | Kein Tool zuverlaessig | - immer eine Team-Entscheidung am review-by-Termin |

## Referenzen

- https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/
- https://kubernetes.io/docs/reference/labels-annotations-taints/audit-annotations/
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/
