#!/bin/bash
NAMESPACE=kubernetes-dashboard
if kubectl get namespace $NAMESPACE; then
    kubectl delete namespace $NAMESPACE
fi