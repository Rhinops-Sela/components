#!/bin/bash

NAMESPACE=kafka
RELEASE=kafka

if kubectl get namespace $NAMESPACE; then
  helm uninstall $RELEASE -n $NAMESPACE
  kubectl delete namespace $NAMESPACE
fi
