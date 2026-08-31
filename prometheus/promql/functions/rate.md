# rate() - Wie funktioniert das ? 

## Kurzbeschreibung

 * `rate()` ist eine **Funktion in PromQL** – genauer gesagt eine sogenannte **Range-Vector-Funktion**.

### Details zu `rate()`

* **Typ:** Funktion
* **Input:** Ein **Range Vector** (also z. B. `metric[5m]`)
* **Zweck:** Berechnet die **durchschnittliche Änderungsrate pro Sekunde** eines Counters über das angegebene Zeitfenster.

### Beispiel:

```promql
rate(http_requests_total[5m])
```

→ `http_requests_total[5m]` ist der Range Vector: alle Werte dieser Zeitreihe der letzten 5 Minuten.
→ `rate()` berechnet aus diesen Werten die durchschnittliche Steigerung pro Sekunde (unter Berücksichtigung von Counter-Resets).

---

### Kurz gesagt:

✅ `rate()` ist eine eingebaute **PromQL-Funktion**
✅ funktioniert **nur mit Range Vectors**,
✅ und ist **für Counter-Metriken gedacht**.

## 🧁 Stell dir vor:

Du hast einen **Zähler (metrics type: counter) **, der **jedes Mal um 1 hochzählt**, wenn jemand einen Muffin isst. Du schaust alle paar Minuten auf diesen Zähler.

---

## 🕒 Beispiel:

Du schaust **alle Minute** auf den Zähler und schreibst die Zahl auf:

| Uhrzeit | Gesehene Zahl auf dem Zähler |
| ------- | ---------------------------- |
| 12:00   | 100 Muffins gegessen         |
| 12:01   | 110                          |
| 12:02   | 125                          |
| 12:03   | 135                          |
| 12:04   | 150                          |
| 12:05   | 160                          |

---

## ❓Frage:

Wie viele Muffins wurden **in den letzten 5 Minuten** gegessen, und **wie viele pro Sekunde**?

---

## 🧮 Schritt für Schritt:

1. **Vergleiche den Anfang und das Ende:**

   * Am Anfang (12:00): 100 Muffins
   * Am Ende (12:05): 160 Muffins

2. **Wieviel Unterschied?**

   * 160 - 100 = **60 Muffins** in 5 Minuten

3. **Wie viele Sekunden sind das?**

   * 5 Minuten = **300 Sekunden**

4. **Wie viele pro Sekunde?**

   * 60 ÷ 300 = **0,2 Muffins pro Sekunde**

---

## 🧪 Das ist genau das, was `rate()` macht:

```promql
rate(muffin_eaten_total[5m]) = 0.2
```

Er schaut:

* Wie stark hat sich die Zahl in den letzten 5 Minuten verändert?
* Teilt das durch die Zeit (300 Sekunden)
* Als Ergebnis bekomme ich die durschnittliche Änderung pro Sekunde (in den letzten 5 Minuten)

---

## 📌 Wichtig:

* Er **zählt nicht nur den letzten Wert**.
* Er **vergleicht Anfang und Ende**.
* Er **berechnet eine Durchschnittsgeschwindigkeit** (wie schnell gegessen wurde).

---

So wie ein Tacho im Auto zeigt, wie schnell du gerade fährst, zeigt `rate()` wie schnell der Counter gewachsen ist – **pro Sekunde im Durchschnitt**.

---

Möchtest du so eine einfache Erklärung als kleine Grafik für dein Training?
