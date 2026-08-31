# Service returns no data 

## Prepare 

  * Delete deployment

```
kubectl -n web-demo get pods -l app=nginx 
kubectl -n web-demo delete deploy nginx
 

```

## Setup Alert 

![image](https://github.com/user-attachments/assets/fcf54cce-0f2e-4e4a-8697-8f51de9388bb)

![image](https://github.com/user-attachments/assets/7c5b575d-0a80-4777-b3f3-53a1188f8720)

## Click on 

```
Preview and alert condition
```

## Safe and exit rules 

```
Safe rule and exit 
```

## Alert ausklappen und warten bis er feuert 

  1. Erst pending (dauert einen Moment)
  2. Dann firing und es kommt ein Benachrichtigung per Slack 

## ✅ Grafana Unified Alert Example: "No Data" for a Job

### 📌 Use the `absent()` function

Grafana can alert when `absent(up{job="myjob"})` returns something — meaning no data is present.

### 🎯 Step-by-step (in Grafana UI)

1. **Go to Alerting → Alert Rules**
2. Click **"Create alert rule"**
3. Set **Data source** to your **Prometheus**
4. Add a **query** like this:

```promql
absent(up{job="myjob"})
```

5. In **Conditions**, set:

   * **WHEN**: `Query (A)` `returns a number`
   * **IS ABOVE**: `0`

   This works because `absent()` returns `1` if the series is absent.

6. Under **Alert Details**, give it a name like:
   `No data for job "myjob"`

7. Configure **Contact Points**, **Labels**, etc.

