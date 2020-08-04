#!/bin/bash
NAMESPACE=fluentd
RELEASE=fluentd


if kubectl get namespace $NAMESPACE; then
  kubectl delete -f configmap.yaml
  kubectl delete -f fluentd.yaml
  kubectl delete namespace $NAMESPACE
fi
