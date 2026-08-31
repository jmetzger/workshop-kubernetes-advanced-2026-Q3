# Problems with istio/samples/add-ons/loki.html 

## What is it ?

```
The loki stateful set cannot get deployed,
because persistentvolumeclaimtemplates in statefulset does not work
```

## Why ?

  * There must be storageclass

```
kubectl get storageclass
# but
no resources found
```

## How to solve ? 

```
We need to rollout a storageclass as follows:
https://github.com/digitalocean/csi-digitalocean#installing-to-kubernetes

1. Steps create api-access key
2. Rollout 

But, some prerequisites must be fullfilled:
# We need to check those first
--allow-privileged flag must be set to true for the API server
--feature-gates=KubeletPluginsWatcher=true,CSINodeInfo=true,CSIDriverRegistry=true must set for api-server and kubelets.


```
