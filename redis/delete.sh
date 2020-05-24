#!/bin/bash


NAMESPACE=redis
RELEASE=redis


if kubectl get namespace $NAMESPACE; then
  helm uninstall $RELEASE -n $NAMESPACE
  kubectl delete namespace $NAMESPACE
fi
