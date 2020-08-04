#!/bin/bash
NAMESPACE=zipkin

if ! kubectl get namespace $NAMESPACE
then
  kubectl create ns $NAMESPACE
  kubectl apply -f zipkin
else
  echo $NAMESPACE exists
fi