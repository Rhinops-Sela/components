#!/bin/bash
NAMESPACE=datadog

if ! kubectl get namespace $NAMESPACE
then
  kubectl apply -f dashboard
else
  echo $NAMESPACE exists
fi