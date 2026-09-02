# Splunk-Funktionsuebersicht: Menuepunkte und Kubernetes-Relevanz

Was Splunk Enterprise alles kann, zugeordnet zu den echten Menuepunkten der Web-UI - und
die Einschaetzung, ob das jeweilige Feature fuer *dieses* Kubernetes-Training gebraucht wird.

Verifiziert an der laufenden externen Instanz aus [UEBERSICHT.md](UEBERSICHT.md) /
[uebungen/02-externe-splunk-vm.md](uebungen/02-externe-splunk-vm.md):
`https://splunk-external.do.t3isp.de`, Splunk 10.4.2, Stand 31.08.2026. 

## App-Auswahl (linke Seitenleiste)

| App | Was sie tut | Fuer K8s-Training gebraucht? |
|---|---|---|
| Search & Reporting | Kernanwendung: Suche, Dashboards, Alerts, Reports | Ja - das ist die App, in der die ganze Uebung 4 stattfindet |
| Audit Trail | Protokolliert Zugriffe/Aenderungen auf die Splunk-Instanz selbst | Nein - Audit der Splunk-Administration, nicht des Clusters |
| Data Management | Verwaltung von Splunk-Cloud-/Edge-Processor-Pipelines | Nein - zielt auf Splunk-eigene Cloud-Infrastruktur, nicht relevant fuer eine einzelne Standalone-VM |
| Discover Splunk Observability Cloud | Bewirbt das separate SaaS-Produkt Splunk Observability Cloud (APM/Infra-Monitoring) | Nein - anderes, kostenpflichtiges Produkt, kein Teil dieser Uebung |
| Splunk Secure Gateway | Koppelt die Splunk-Mobile-App per QR-Code an die Instanz | Nein - Mobile-Zugriff ist fuer eine Trainingsumgebung ohne Mehrwert |
| Upgrade Readiness App | Prueft Apps/Konfiguration vor einem Splunk-Versions-Upgrade | Nein - Instanz wird nach der Uebung wieder abgebaut, kein Upgrade-Pfad noetig |

## Search & Reporting App (linke Symbolleiste in der App)

| Menuepunkt | Was er tut | Fuer K8s-Training gebraucht? |
|---|---|---|
| Search | SPL-Suche gegen den Index, Kern-Feature | Ja - zentral in [Uebung 4](uebungen/04-log-suche-crashloop-debugging.md), Schritte 3+4 |
| Analytics Workspace | Klick-basierte Alternative zu SPL (Pivot-Nachfolger) fuer Nutzer ohne SPL-Kenntnisse | Nein - Trainingsziel ist SPL selbst zu ueben, nicht der Klick-Weg drumherum |
| Datasets | Verwaltung von Data Models/Table Datasets als wiederverwendbare Datenbasis fuer Pivot | Nein - Aufbauthema, ueberschneidet sich mit Analytics Workspace, nicht im Scope |
| Reports | Gespeicherte Suchen mit Zeitplan, Ergebnis-Export | Nein direkt - waere ein sinnvoller naechster Schritt nach Uebung 4, aber kein eigener Uebungsinhalt |
| Alerts | Bedingte Benachrichtigung aus einer Suche heraus (E-Mail, Webhook, Skript) | Ja - explizit in [Uebung 4, Schritt 5](uebungen/04-log-suche-crashloop-debugging.md) als optionaler Schritt angelegt (BackOff-Alert) |
| Dashboards | Visualisierungen/Panels aus gespeicherten Suchen | Optional - "Visualize your data" wird auf der Startseite beworben, ist aber keine eigene Uebung; waere naheliegende Erweiterung fuer ein Kubernetes-Log-Dashboard |
| Modules | SPL2-Suchmodule (mehrere Suchen kombinieren, neueres API-Konzept) | Nein - SPL2 ist ein Splunk-internes Nachfolgekonzept zu SPL, kein Kubernetes-Bezug |

**Was ist SPL2:** die von Splunk geplante Nachfolgesprache zu SPL - naeher an SQL/Pipe-Syntax
aus einem Guss, gedacht um Suchbausteine als wiederverwendbare "Module" zu buendeln und
gleichermassen in Splunk Cloud, Splunk Enterprise und Data-Pipeline-Produkten (z.B. Edge
Processor) einsetzbar zu sein. Fuer dieses Training ohne Bedeutung: die Uebungen nutzen
durchgehend klassisches SPL, siehe [Uebung 4](uebungen/04-log-suche-crashloop-debugging.md).

### Screenshots: jeder Menuepunkt einzeln

Jeder Punkt der linken Symbolleiste angeklickt, mit rotem Rahmen um das jeweilige Icon
markiert (Screenshots aus der laufenden Instanz, Stand 31.08.2026):

**Search**
![Search](screenshots-menue/01-search.jpg)
SPL-Eingabefeld plus Suchhistorie - der Standard-Einstiegspunkt der App. Sinnvoll fuer die
Kubernetes-Anbindung: ja, das ist der zentrale Arbeitsplatz aus [Uebung 4](uebungen/04-log-suche-crashloop-debugging.md).

**Analytics Workspace**
![Analytics Workspace](screenshots-menue/02-analytics-workspace.jpg)
Klick-basiertes Analyse-Interface (Metriken/Datasets per Drag-and-Drop statt SPL zu tippen).
Sinnvoll fuer die Kubernetes-Anbindung: nein - das Training vermittelt bewusst SPL direkt,
dieser Weg drumherum ist kein Uebungsinhalt.

**Datasets**
![Datasets](screenshots-menue/03-datasets.jpg)
Verwaltung wiederverwendbarer, strukturierter Datensichten (Basis fuer Analytics
Workspace/Pivot). Sinnvoll fuer die Kubernetes-Anbindung: nein - Aufbauthema ohne eigenen
Uebungsschritt.

**Reports**
![Reports](screenshots-menue/04-reports.jpg)
Liste gespeicherter Suchen mit Zeitplan (hier bereits 8 vorinstallierte Splunk-Standardreports
zu sehen, z.B. "Errors in the last 24 hours" - keiner davon Kubernetes-spezifisch). Sinnvoll
fuer die Kubernetes-Anbindung: nein direkt - waere aber der naheliegende naechste Schritt, um
die BackOff-Suche aus Uebung 4 dauerhaft zu speichern.

**Alerts**
![Alerts](screenshots-menue/05-alerts.jpg)
Liste aller konfigurierten Alerts (Bedingung -> Aktion). Sinnvoll fuer die
Kubernetes-Anbindung: ja - hier taucht der optionale BackOff-Alert aus
[Uebung 4, Schritt 5](uebungen/04-log-suche-crashloop-debugging.md) auf, falls angelegt.

**Dashboards**
![Dashboards](screenshots-menue/06-dashboards.jpg)
Uebersicht/Neuanlage von Dashboards (Dashboard Studio oder Classic/Simple-XML). Sinnvoll fuer
die Kubernetes-Anbindung: optional - kein Pflichtschritt der Uebung, aber naheliegende
Erweiterung fuer ein CrashLoopBackOff-Uebersichts-Dashboard.

**Modules**
![Modules](screenshots-menue/07-modules.jpg)
SPL2-Suchmodule. Auf dieser Instanz tatsaechlich nicht nutzbar - Splunk meldet "Unable to
access SPL2 modules because the required 'data orchestrator' component is not available."
Sinnvoll fuer die Kubernetes-Anbindung: nein - SPL2 ist ein separates, neueres
Splunk-Suchkonzept ohne Kubernetes-Bezug, und auf dieser Standalone-Instanz fehlt ohnehin die
dafuer noetige Zusatzkomponente.

## Activity-Menue (oben, Symbol neben der Suchlupe)

| Menuepunkt | Was er tut | Fuer K8s-Training gebraucht? |
|---|---|---|
| Jobs | Laufende/abgeschlossene Suchjobs verwalten (abbrechen, Ergebnisse nachladen) | Nein direkt - nuetzlich falls eine Suche in Uebung 4 haengt, aber kein eigener Uebungsinhalt |
| Triggered Alerts | Historie ausgeloester Alerts | Nein direkt - haengt am optionalen Alert aus Uebung 4, Schritt 5 |

## Fazit

Fuer dieses Training zaehlen im Kern nur wenige Menuepunkte wirklich: **Search** und
**Alerts** aus der Search & Reporting App - das deckt den Weg "Log/Event trifft in Splunk
ein -> wird per SPL gefunden -> loest optional einen Alert aus" ab, der
[Uebung 4](uebungen/04-log-suche-crashloop-debugging.md) traegt. Analytics Workspace,
Datasets, Reports und Modules sind Aufbau- bzw. Alternativkonzepte ohne eigenen
Uebungsschritt, Dashboards eine naheliegende, aber optionale Erweiterung. Das
Settings-Menue (Administration der Splunk-Instanz selbst: Server, Lizenz, Indizes,
Forwarding, Clustering, Nutzer/Rollen) ist bewusst nicht Teil dieser Uebersicht - es
betrifft den Betrieb von Splunk als Produkt, nicht die Bedienung durch einen
Kubernetes-Nutzer, und wird stattdessen ueber die IaC-Schritte in
[Uebung 2](uebungen/02-externe-splunk-vm.md) und
[Uebung 3](uebungen/03-forwarder-an-externe-splunk.md) automatisiert statt per Klick
konfiguriert.
