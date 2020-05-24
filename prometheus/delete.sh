#!/bin/bash
NAMESPACE=prometheus
RELEASE=prometheus


if kubectl get namespace $NAMESPACE; then
  helm uninstall $RELEASE -n $NAMESPACE
  kubectl delete namespace $NAMESPACE
fi
