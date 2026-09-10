# Find out your permissions 

## A specific command 

```
kubectl auth can-i get pods 
```

## List all 

```
kubectl auth can-i --list
```

## Fuer einen anderen Nutzer (z.B. ServiceAccount)

```
kubectl auth can-i --list --as system:serviceaccount:default:training
```

Praktisch kombinierbar mit der [praktischen RBAC-Uebung](../rbac-create-user-kubernetes-1-25.md):
zeigt alle erlaubten Verben/Ressourcen des ServiceAccount auf einen Blick,
statt jeden Befehl einzeln mit `can-i get ...` durchzutesten.
