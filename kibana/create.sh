#!/bin/bash
NAMESPACE=kibana
if ! kubectl get namespace $NAMESPACE
then
  kubectl create namespace $NAMESPACE
  kubectl apply -f deployment.yaml -n $NAMESPACE
  kubectl apply -f service.yaml -n $NAMESPACE
else
  echo $NAMESPACE exists
fi