# Warum Calico-NetworkPolicies statt der Standard-NetworkPolicy von Kubernetes?

## Kurzfassung

  * Die Kubernetes-NetworkPolicy ist der kleinste gemeinsame Nenner:
    portabel ueber alle CNI-Provider (Calico, Cilium, ...), aber bewusst
    eingeschraenkt.
  * Die Calico-Policies (`projectcalico.org/v3`) sind ein Superset:
    alles, was die Standard-Policy kann, plus cluster-weite Policies,
    Deny-Regeln, Reihenfolge und mehr.
  * Beide lassen sich mischen - Calico wertet Standard- und
    Calico-Policies gemeinsam aus.

## Was die Standard-NetworkPolicy kann

  * Namespaced: gilt immer nur in ihrem Namespace
  * Whitelist-Prinzip: sobald eine Policy auf einen Pod matcht,
    ist alles andere verboten - es gibt nur "Allow"-Regeln
  * Selektoren: `podSelector`, `namespaceSelector`, `ipBlock`
  * Ports/Protokolle: TCP, UDP, SCTP
  * Wichtig: Kubernetes selbst setzt NICHTS durch - die Umsetzung
    macht immer der CNI-Provider (bei uns: Calico)

## Grenzen der Standard-NetworkPolicy

  * Kein cluster-weites default-deny mit EINEM Objekt -
    man braucht eine eigene Policy pro Namespace
  * Keine expliziten Deny-Regeln (nur implizites Deny durch Whitelisting)
  * Keine Reihenfolge/Prioritaeten zwischen Policies
  * Kein Schutz der Nodes selbst (nur Pod-Traffic)
  * Kein Logging von Policy-Entscheidungen
  * Nur einfache Label-Gleichheit als Selektor

## Was Calico zusaetzlich bietet

| Feature | Standard NetworkPolicy | Calico |
|---------|------------------------|--------|
| Geltungsbereich | nur Namespace | NetworkPolicy (Namespace) + GlobalNetworkPolicy (Cluster) |
| Aktionen | nur Allow (implizit) | Allow, Deny, Log, Pass |
| Reihenfolge | keine | `order`-Feld |
| Selektoren | Label-Gleichheit | Ausdruecke: `has()`, `in`, `!=`, `&&`, `all()` |
| ServiceAccounts | nein | `serviceAccountSelector` |
| Nodes/Hosts schuetzen | nein | HostEndpoints, `preDNAT` (z.B. NodePorts) |
| ICMP-Regeln | nein | ja |
| Policies testen | nein | Staged Policies (ab 3.29), Tiers (ab 3.30) |

  * Praktisch am wichtigsten fuer uns:
    * **GlobalNetworkPolicy**: ein cluster-weites default-deny statt
      einer Kopie pro Namespace (siehe Uebung)
    * **order**: definierte Auswertungsreihenfolge statt "alle Policies
      werden zusammengeworfen"
    * **Log-Action**: sichtbar machen, WELCHE Regel Traffic verwirft

## Daumenregel: Wann nehme ich was?

  * **Standard-NetworkPolicy**: einfache App-Isolation innerhalb eines
    Namespaces, oder wenn Manifests portabel bleiben sollen
    (z.B. Helm-Charts fuer fremde Cluster)
  * **Calico-Policies**: cluster-weite Grundregeln (default-deny),
    explizite Deny-Regeln, Compliance-Anforderungen, Node-Schutz,
    Policy-Debugging
  * Mischen ist ueblich: Plattform-Team setzt GlobalNetworkPolicies,
    App-Teams schreiben Standard-Policies fuer ihre Namespaces.
    Calico liest die Standard-Policies direkt ein und wertet sie
    zusammen mit den Calico-Policies aus.

## Referenzen

  * https://docs.tigera.io/calico/latest/network-policy/get-started/calico-policy/calico-network-policy
  * https://docs.tigera.io/calico/latest/network-policy/get-started/kubernetes-policy/kubernetes-network-policy
