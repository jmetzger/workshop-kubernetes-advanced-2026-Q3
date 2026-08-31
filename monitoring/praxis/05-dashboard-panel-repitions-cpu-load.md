# CPU Last für alle Nodes anzeigen 

## Schritt 1: bestehendes Dashboard (provisioned) - exportieren bzw. importieren

  * Dashboard (Node Exporter -> Nodes) aufrufen
  * Oben rechts: Export -> Export as JSON

## Schritt 2: Neues Dashboard durch import erstellen 

  1. Oben rechts: + Zeichen: Import Dashboard
  1. Copy to clipboard ![image](https://github.com/user-attachments/assets/446d97c4-0e84-49e8-a436-31a72179fb29)
  2. + und import dashboard

![image](https://github.com/user-attachments/assets/fe51b22a-9ad1-43ec-a307-5cad58c9fe1d)

## Schritt 3: Dashboard speichern 

  * Achtung: Beim Speichern des Dashboards anderen Namen und andere ID angeben
    (einfach die uid um +1 hochzählen), vorher: change uid anklicken 
  * dann **Import** - Button klicken

## Schritt 4: Dashboard ausdünnen (alle nicht benötigte Panels raus)

  * Wir löschen alles ausser das CPU - Panel 

  1. Oben rechts neben **Settings** auf **Edit** klicken
  1. Neben dem jeweiligen Panel auf die DREI-PUNKTE klicken:

![image](https://github.com/user-attachments/assets/18988150-2ff3-45a2-8938-fac448e6c7a1)

  1. Auf Remove klicken
  1. Alle nicht benötigen Rows löschen (Neben der Row auf den Papierkorb) 

## Schritt 5: Visualisierung von CPU ändern auf Graph 

  * Vorher:

![image](https://github.com/user-attachments/assets/472abb6c-24e2-4d62-b56a-2299b271936a)

  * dann: rechts auf die 3 Punkte oben rechts edit

![image](https://github.com/user-attachments/assets/54e41528-e683-4974-9023-2069b47efcf2)

  * Dann Visualisierung ändern in ->

![image](https://github.com/user-attachments/assets/669fd2e4-fea5-49b1-9f2a-bed15c827b1f)

  * Nachher:

![image](https://github.com/user-attachments/assets/b34fdde3-f987-4732-8efe-126b4093d869)

## Schritt 6: Titel auf dynamisch ändern 

  * Wir setzen hier die Variable $instance ein

![image](https://github.com/user-attachments/assets/9f1c6e3d-6d9a-45dd-b746-2664229921dd)

  * Diese wurde bereits unter Settings -> Variablen definiert.

![image](https://github.com/user-attachments/assets/e5b67110-18d6-46e1-ae11-359b8f75da6b)

![image](https://github.com/user-attachments/assets/bf3f41e3-0f72-419f-af97-c33467c017c0)

## Schritt 7: Variable "instance" auf Multi-Auswahl ändern 

  1. Unter settings: siehe 6.
  2. instance anklicken

![image](https://github.com/user-attachments/assets/bb57321e-6529-40f8-98de-2544f51d24ff)

  3. Multi-Value anklicken:

![image](https://github.com/user-attachments/assets/cf95b185-f536-4c5d-9518-714553802aa9)

  4. Wichtig: Dashboard speichern

```bash
    Durch Multi-Value:
    Dadurch lässt sich nicht nur eine Instance (ein Server), sondern mehrere auswählen
```
![image](https://github.com/user-attachments/assets/382f8e66-e3e3-47f4-a60f-b6afa56727b0)


![image](https://github.com/user-attachments/assets/f1b18383-493f-4c2c-ad05-4d9c47837b28)

  5. Problem - no data beheben

 * Durch umstellung auf Multi-Value muss die Query geändert werden.
 * Es darf nicht mehr explizit nach einer instance gefragt werden, sondern mit regex

```
# Vorher
(
  (1 - sum without (mode) (rate(node_cpu_seconds_total{job="node-exporter", mode=~"idle|iowait|steal", instance="$instance", cluster="$cluster"}[$__rate_interval])))
/ ignoring(cpu) group_left
  count without (cpu, mode) (node_cpu_seconds_total{job="node-exporter", mode="idle", instance="$instance", cluster="$cluster"})
)
```

```
# Ändern in
(
  (1 - sum without (mode) (rate(node_cpu_seconds_total{job="node-exporter", mode=~"idle|iowait|steal", instance=~"$instance", cluster="$cluster"}[$__rate_interval])))
/ ignoring(cpu) group_left
  count without (cpu, mode) (node_cpu_seconds_total{job="node-exporter", mode="idle", instance=~"$instance", cluster="$cluster"})
)

```

  * Dashboard speichern

## Schritt 5: Auf panel repetitions umstellen 

  1. Bei den Panel Settings runterscrollen

![image](https://github.com/user-attachments/assets/ee679e09-de0f-471d-9324-2de4398c89b8)


  2. ... und instance auswählen

![image](https://github.com/user-attachments/assets/400c56dc-c97c-4c55-84f0-23e881e93384)

  3. Max per row: auf 2 stellen

  4. Dashboard speichern

## Schritt 6: Testen: Dashboard muss nochmal neu geladen zu werden 

  1. Auf Back to Dashboard klicken
  2. Die neue Ausgabe sollte erscheinen (evtl. oben bei instances nochmal alle auswählen)

 

