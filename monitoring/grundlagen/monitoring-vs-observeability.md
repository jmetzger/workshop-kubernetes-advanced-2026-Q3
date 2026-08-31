# Unterschiede zwischen Monitoring und Observeability 

Der Unterschied zwischen **Kubernetes Monitoring** und **Observability** liegt vor allem im **Ziel**, **Umfang** und **Vorgehen**. Hier eine klare Gegenüberstellung:

---

### 🔍 **Monitoring** (Beobachtung)

**Definition:**
Monitoring ist das **Sammeln und Anzeigen** von Metriken und Logs, um den **Zustand eines Systems zu überwachen**.

**Merkmale:**

* Fokus auf bekannte Metriken, Fehler und Schwellenwerte
* Alarme bei bekannten Problemen (z. B. CPU-Auslastung > 90 %)
* Reaktiv: Man erkennt, *dass* etwas nicht stimmt

**Beispiele:**

* CPU-, RAM-, Netzwerkverbrauch von Pods
* Anzahl von HTTP 500 Errors
* Alerts bei Pod-Crashes

**Werkzeuge:**

* Prometheus
* Grafana
* Alertmanager
* Metrics Server

---

### 🧠 **Observability** (Beobachtbarkeit)

**Definition:**
Observability beschreibt die **Fähigkeit**, den **internen Zustand** eines Systems allein durch seine externen Outputs (Logs, Metriken, Traces) **verstehen** zu können.

**Merkmale:**

* Ermöglicht Ursachenanalyse auch für **unbekannte Probleme**
* Proaktiv: Man kann *warum* etwas passiert ist, herausfinden
* Nutzt drei Hauptsäulen:

  * **Metriken** (z. B. Requests/sec)
  * **Logs** (z. B. Stacktraces)
  * **Traces** (z. B. verteilte Aufrufe zwischen Microservices)

**Beispiele:**

* Warum ist ein Request langsam? (Trace-Analyse)
* Welche Kette von Services war beteiligt?
* Korrelation von Logs mit Metrik-Anomalien

**Werkzeuge:**

* OpenTelemetry
* Grafana Tempo / Jaeger (für Tracing)
* Loki (für Logs)
* Elastic Stack
* Honeycomb, Lightstep

---

### ⚖️ Vergleich zusammengefasst

| Aspekt             | Monitoring                       | Observability                                  |
| ------------------ | -------------------------------- | ---------------------------------------------- |
| Ziel               | Systemzustand überwachen         | Systemverhalten verstehen                      |
| Fokus              | Bekannte Probleme erkennen       | Ursachen auch unbekannter Probleme analysieren |
| Methoden           | Metriken, Schwellenwerte, Alarme | Logs, Metriken, Traces kombiniert              |
| Reaktiv / Proaktiv | Reaktiv                          | Proaktiv / Diagnostisch                        |
| Typische Fragen    | Ist etwas kaputt?                | Warum ist etwas kaputt?                        |

---
