# Egress auf Domain-Namen: Cilium (Community) vs. Calico (Enterprise)

## Kurzfassung

  * **Cilium** kann Egress-Regeln direkt auf FQDNs/Domainnamen schreiben
    (`toFQDNs` in der `CiliumNetworkPolicy`) - und das bereits in der
    Community/OSS-Edition (seit Cilium 1.1).
  * **Calico** hat eine vergleichbare domainbasierte Egress-Policy nur
    in der kommerziellen Tigera-Enterprise-Variante in voller Form -
    in der Calico-OSS-Version fehlt das Aequivalent.

## Warum das relevant ist

  * Klassische NetworkPolicy/GlobalNetworkPolicy-Egress-Regeln arbeiten
    mit `ipBlock`/CIDRs. Bei extern gehosteten Diensten mit wechselnden
    IPs (SaaS-APIs, CDNs, Cloud-Endpunkte) ist das unpraktisch bis
    unmoeglich sauber zu pflegen.
  * `toFQDNs` loest das, indem Cilium DNS-Antworten beobachtet und die
    aufgeloesten IPs automatisch in die Egress-Policy uebernimmt -
    Regeln lassen sich direkt auf Domainnamen formulieren, z.B.
    "dieser Pod darf nur zu `api.stripe.com`".

## Beispiel (Cilium, `toFQDNs`)

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-only-stripe-api
spec:
  endpointSelector:
    matchLabels:
      app: checkout
  egress:
    - toFQDNs:
        - matchName: "api.stripe.com"
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
```

## Einordnung

  * Fuer Calico gibt es keine 1:1-Entsprechung in der Community-Version -
    Domain-basierte DNS-Policy zaehlt dort zu den Enterprise-Features
    (siehe Tigera-Vergleich unten).
  * Fuer unsere Trainingsumgebung (Calico als CNI) heisst das: Egress
    auf externe Domains bleibt mit CIDRs/`ipBlock` geloest, nicht mit
    Domainnamen direkt.

## Referenzen

  * https://docs.cilium.io/en/stable/security/policy/language/#dns-based
  * https://www.tigera.io/blog/advantages-of-calicos-dns-policy-implementation-over-ciliums-dns-policy-implementation/
  * https://www.tigera.io/learn/guides/cilium-vs-calico/
