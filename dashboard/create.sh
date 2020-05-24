#!/bin/bash
NAMESPACE=kubernetes-dashboard

if ! kubectl get namespace $NAMESPACE
then
  kubectl apply -f dashboard
  kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}') > ../../output/dashboard-admin-secret
else
  echo $NAMESPACE exists
fi