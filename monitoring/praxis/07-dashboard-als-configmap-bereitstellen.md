# Dashboard als configmap bereitstellen

## Step 1: on ssh-client

```
cd
mkdir -p manifests
cd manifests
mkdir dashboard
cd dashboard
```

```
nano 01-configmap-dashboard.yml
```

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboard-pods
  labels:
    grafana_dashboard: "1"  # Wichtig: Wird vom Grafana-Operator oder Helm erkannt
    app.kubernetes.io/name: grafana
data:
  pods-dashboard.json: |

#Inhalt reinkopieren aus dem Export von dashboard aus grafana
# 
```
![image](https://github.com/user-attachments/assets/fa898c83-30d7-4b6b-9656-f1629f590ed6)


 * Achtung: Der __inputs__ - Bereich funktioniert nicht über die ConfigMap nur über die Web Gui
 * Hier ein funktionierendes Beispiel:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboard-pods
  labels:
    grafana_dashboard: "1"  # Wichtig: Wird vom Grafana-Operator oder Helm erkannt
    app.kubernetes.io/name: grafana
data:
  pods-dashboard.json: |
    {
      "__inputs": {},
      "__elements": {},
      "__requires": [
        {
          "type": "panel",
          "id": "bargauge",
          "name": "Bar gauge",
          "version": ""
        },
        {
          "type": "panel",
          "id": "gauge",
          "name": "Gauge",
          "version": ""
        },
        {
          "type": "grafana",
          "id": "grafana",
          "name": "Grafana",
          "version": "12.0.0"
        },
        {
          "type": "datasource",
          "id": "prometheus",
          "name": "Prometheus",
          "version": "1.0.0"
        },
        {
          "type": "panel",
          "id": "table",
          "name": "Table",
          "version": ""
        },
        {
          "type": "panel",
          "id": "timeseries",
          "name": "Time series",
          "version": ""
        }
      ],
      "annotations": {
        "list": [
          {
            "builtIn": 1,
            "datasource": {
              "type": "grafana",
              "uid": "-- Grafana --"
            },
            "enable": true,
            "hide": true,
            "iconColor": "rgba(0, 211, 255, 1)",
            "name": "Annotations & Alerts",
            "type": "dashboard"
          }
        ]
      },
      "editable": true,
      "fiscalYearStartMonth": 0,
      "graphTooltip": 0,
      "id": null,
      "links": [],
      "panels": [
        {
          "collapsed": true,
          "gridPos": {
            "h": 1,
            "w": 24,
            "x": 0,
            "y": 0
          },
          "id": 9,
          "panels": [],
          "title": "Übersicht",
          "type": "row"
        },
        {
          "datasource": {
            "type": "prometheus"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "palette-classic"
              },
              "custom": {
                "axisBorderShow": false,
                "axisCenteredZero": false,
                "axisColorMode": "text",
                "axisLabel": "",
                "axisPlacement": "auto",
                "barAlignment": 0,
                "barWidthFactor": 0.6,
                "drawStyle": "line",
                "fillOpacity": 0,
                "gradientMode": "none",
                "hideFrom": {
                  "legend": false,
                  "tooltip": false,
                  "viz": false
                },
                "insertNulls": false,
                "lineInterpolation": "linear",
                "lineWidth": 1,
                "pointSize": 5,
                "scaleDistribution": {
                  "type": "linear"
                },
                "showPoints": "auto",
                "spanNulls": false,
                "stacking": {
                  "group": "A",
                  "mode": "none"
                },
                "thresholdsStyle": {
                  "mode": "off"
                }
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green"
                  },
                  {
                    "color": "red",
                    "value": 80
                  }
                ]
              },
              "unit": "mbytes"
            },
            "overrides": []
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 0,
            "y": 1
          },
          "id": 6,
          "options": {
            "legend": {
              "calcs": [],
              "displayMode": "list",
              "placement": "bottom",
              "showLegend": true
            },
            "tooltip": {
              "hideZeros": false,
              "mode": "single",
              "sort": "none"
            }
          },
          "pluginVersion": "12.0.0",
          "targets": [
            {
              "editorMode": "code",
              "expr": "sum by (namespace, pod, container) (\r\n  container_memory_usage_bytes{container!=\"\"}\r\n) / (1024 * 1024)",
              "legendFormat": "{{namespace}} / {{pod}} / {{container}}",
              "range": true,
              "refId": "A",
              "datasource": {
                "type": "prometheus"
              }
            }
          ],
          "title": "Memory-Nutzung pro Container",
          "type": "timeseries"
        },
        {
          "datasource": {
            "type": "prometheus"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "thresholds"
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green"
                  },
                  {
                    "color": "red",
                    "value": 10
                  }
                ]
              }
            },
            "overrides": []
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 12,
            "y": 1
          },
          "id": 1,
          "options": {
            "displayMode": "basic",
            "legend": {
              "calcs": [],
              "displayMode": "list",
              "placement": "bottom",
              "showLegend": false
            },
            "maxVizHeight": 300,
            "minVizHeight": 16,
            "minVizWidth": 8,
            "namePlacement": "auto",
            "orientation": "horizontal",
            "reduceOptions": {
              "calcs": [
                "lastNotNull"
              ],
              "fields": "",
              "values": false
            },
            "showUnfilled": true,
            "sizing": "auto",
            "valueMode": "color"
          },
          "pluginVersion": "12.0.0",
          "targets": [
            {
              "datasource": {
                "type": "prometheus"
              },
              "editorMode": "code",
              "expr": "count by (namespace) (kube_pod_status_phase{phase=~\"Pending|Failed|Unknown\"})\r\n",
              "legendFormat": "__auto",
              "range": true,
              "refId": "A"
            }
          ],
          "title": "Fehlgeschlagene Pods je Namespace",
          "type": "bargauge"
        },
        {
          "collapsed": false,
          "gridPos": {
            "h": 1,
            "w": 24,
            "x": 0,
            "y": 9
          },
          "id": 4,
          "panels": [],
          "title": "Zeile 1",
          "type": "row"
        },
        {
          "datasource": {
            "type": "prometheus"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "thresholds"
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "text"
                  },
                  {
                    "color": "red",
                    "value": 0
                  },
                  {
                    "color": "green",
                    "value": 1
                  }
                ]
              }
            },
            "overrides": []
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 0,
            "y": 10
          },
          "id": 7,
          "options": {
            "minVizHeight": 75,
            "minVizWidth": 75,
            "orientation": "auto",
            "reduceOptions": {
              "calcs": [
                "lastNotNull"
              ],
              "fields": "",
              "values": false
            },
            "showThresholdLabels": false,
            "showThresholdMarkers": true,
            "sizing": "auto"
          },
          "pluginVersion": "12.0.0",
          "targets": [
            {
              "editorMode": "code",
              "expr": "max by (pod, container) (kube_pod_container_status_ready{namespace=\"$namespace\"})",
              "legendFormat": "{{container}}->{{pod}}",
              "range": true,
              "refId": "A",
              "datasource": {
                "type": "prometheus"
              }
            }
          ],
          "title": "Container Ready Status als Gauge",
          "type": "gauge"
        },
        {
          "datasource": {
            "type": "prometheus"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "palette-classic"
              },
              "custom": {
                "axisBorderShow": false,
                "axisCenteredZero": false,
                "axisColorMode": "text",
                "axisLabel": "",
                "axisPlacement": "auto",
                "barAlignment": 0,
                "barWidthFactor": 0.6,
                "drawStyle": "line",
                "fillOpacity": 0,
                "gradientMode": "none",
                "hideFrom": {
                  "legend": false,
                  "tooltip": false,
                  "viz": false
                },
                "insertNulls": false,
                "lineInterpolation": "linear",
                "lineWidth": 1,
                "pointSize": 5,
                "scaleDistribution": {
                  "type": "linear"
                },
                "showPoints": "auto",
                "spanNulls": false,
                "stacking": {
                  "group": "A",
                  "mode": "none"
                },
                "thresholdsStyle": {
                  "mode": "off"
                }
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green"
                  },
                  {
                    "color": "red",
                    "value": 80
                  }
                ]
              }
            },
            "overrides": []
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 12,
            "y": 10
          },
          "id": 5,
          "options": {
            "legend": {
              "calcs": [],
              "displayMode": "list",
              "placement": "bottom",
              "showLegend": true
            },
            "tooltip": {
              "hideZeros": false,
              "mode": "single",
              "sort": "none"
            }
          },
          "pluginVersion": "12.0.0",
          "targets": [
            {
              "editorMode": "code",
              "expr": "sum by (namespace, pod, container) (\r\n  rate(container_cpu_usage_seconds_total{container!=\"\"}[5m])\r\n) * 1000",
              "legendFormat": "{{namespace}} / {{pod}} / {{container}}",
              "range": true,
              "refId": "A",
              "datasource": {
                "type": "prometheus"
              }
            }
          ],
          "title": "CPU-Nutzung pro Container (millicores)",
          "type": "timeseries"
        },
        {
          "collapsed": false,
          "gridPos": {
            "h": 1,
            "w": 24,
            "x": 0,
            "y": 18
          },
          "id": 2,
          "panels": [],
          "title": "Zeile 2",
          "type": "row"
        },
        {
          "datasource": {
            "type": "prometheus"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "thresholds"
              },
              "custom": {
                "align": "auto",
                "cellOptions": {
                  "type": "auto"
                },
                "inspect": false
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green"
                  },
                  {
                    "color": "red",
                    "value": 80
                  }
                ]
              }
            },
            "overrides": []
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 0,
            "y": 19
          },
          "id": 3,
          "options": {
            "cellHeight": "sm",
            "footer": {
              "countRows": false,
              "fields": "",
              "reducer": [
                "sum"
              ],
              "show": false
            },
            "showHeader": true,
            "sortBy": [
              {
                "desc": false,
                "displayName": "{container=\"alertmanager\", pod=\"alertmanager-prometheus-kube-prometheus-alertmanager-0\"}"
              }
            ]
          },
          "pluginVersion": "12.0.0",
          "targets": [
            {
              "editorMode": "code",
              "expr": "topk(5, sum by (pod, container) (kube_pod_container_status_restarts_total))\r\n",
              "legendFormat": "__auto",
              "range": true,
              "refId": "A",
              "datasource": {
                "type": "prometheus"
              }
            }
          ],
          "title": "Top 5 Container mit höchsten Restarts",
          "type": "table"
        }
      ],
      "schemaVersion": 41,
      "tags": [],
      "templating": {
        "list": [
          {
            "current": {},
            "definition": "label_values(kube_pod_info{job=\"kube-state-metrics\"},namespace)",
            "label": "Namespace",
            "name": "namespace",
            "options": [],
            "query": {
              "qryType": 1,
              "query": "label_values(kube_pod_info{job=\"kube-state-metrics\"},namespace)",
              "refId": "PrometheusVariableQueryEditor-VariableQuery"
            },
            "refresh": 1,
            "regex": "",
            "type": "query"
          }
        ]
      },
      "time": {
        "from": "now-6h",
        "to": "now"
      },
      "timepicker": {},
      "timezone": "browser",
      "title": "JM - Training Dashboard2",
      "uid": "25eb5e8e-1144-443e-ada3-f4a262751b95",
      "version": 13,
      "weekStart": ""
    }
```

```
kubectl apply -f .
```
