# Debug Container / Debug Node 

##  Walkthrough  Debug Container 

```
kubectl run ephemeral-demo --image=registry.k8s.io/pause:3.1 --restart=Never
kubectl exec -it ephemeral-demo -- sh

kubectl debug -it ephemeral-demo --image=busybox 
```

## Example with nginx

```
kubectl run --image=nginx nginx
## debug this container
kubectl debug -it nginx --image=busybox
```

```
# processe des original containers anzeigen
# z.B. nginx
# name des containers rausfinden
kubectl debug -it nginx --target=nginx --image=busybox
```



## Walkthrough Debug Node 

```
kubectl get nodes
# so auch root-rechte auf node 
kubectl debug node/mynode -it --profile=sysadmin --image=ubuntu
```



## Reference 

  * https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#ephemeral-container
