#!/bin/bash
# from https://hub.helm.sh/charts/jetstack/cert-manager/v0.15.0

NAMESPACE=cert-manager
RELEASE=cert-manager


if kubectl get namespace $NAMESPACE; then
  helm uninstall $RELEASE -n $NAMESPACE
  kubectl delete namespace $NAMESPACE
fi
