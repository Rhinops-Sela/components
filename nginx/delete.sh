#!/bin/bash
NAMESPACE=ingress-nginx
RELEASE=controller


if kubectl get namespace $NAMESPACE; then
  # helm uninstall $RELEASE -n $NAMESPACE
  kubectl delete -f aws/deploy.yaml -n $NAMESPACE
  kubectl delete namespace $NAMESPACE
fi
