#!/bin/bash
NAMESPACE=horizontal-pod-scaler

if ! kubectl get namespace $NAMESPACE
then
  kubectl create namespace $NAMESPACE
  kubectl apply -f hpa.yaml -n $NAMESPACE
else
  echo $NAMESPACE exists
fi