#!/bin/bash
NAMESPACE=horizontal-pod-scaler

if kubectl get namespace $NAMESPACE; then
  kubectl delete -f hpa.yaml
  kubectl delete namespace $NAMESPACE
fi
