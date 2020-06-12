#!/bin/bash

#patch core-dns for 'system: "true:NoSchedule"' tolerations
kubectl delete configmap coredns -n kube-system
kubectl apply -f coredns-configmap.yaml -n kube-system
kubectl delete pods -l  k8s-app=kube-dns -n kube-system