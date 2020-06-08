#!/bin/bash
NAMESPACE=datadog
if kubectl get namespace $NAMESPACE; then
    kubectl delete namespace $NAMESPACE
fi