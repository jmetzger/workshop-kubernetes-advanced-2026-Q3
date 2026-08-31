# Notification in Grafana 

To configure which **contact point** to use for an alert in a typical **alerting system** (like Prometheus Alertmanager, Grafana, etc.), the process generally involves **creating routing rules** or **setting labels** that determine how alerts are matched to specific contact points (such as email, Slack, PagerDuty, etc.).

Here’s a general breakdown depending on the platform:

## **Grafana Alerting (Unified Alerting System)**

1. **Create Contact Points** via **Alerting > Contact Points**.

2. **Create Notification Policies** in **Alerting > Notification Policies**:

   * Define **routing rules** that match **labels or conditions**.
   * Attach contact points to each rule.

3. **In Alert Rules**, define **custom labels** that match the notification policies.

---
