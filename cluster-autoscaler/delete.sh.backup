#!/bin/bash
NAMESPACE=cluster-autoscaler
RELEASE=cluster-autoscaler



if kubectl get namespace $NAMESPACE; then
    helm uninstall $RELEASE -n $NAMESPACE 
    kubectl delete namespace $NAMESPACE
fi