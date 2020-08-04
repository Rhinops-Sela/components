#!/bin/bash
NAMESPACE=fluentd
RELEASE=fluentd

if ! kubectl get namespace $NAMESPACE
then
  kubectl create namespace $NAMESPACE
  kubectl apply -f configmap.yaml -n $NAMESPACE
  kubectl apply -f fluentd.yaml -n $NAMESPACE
else
  echo $NAMESPACE exists
fi