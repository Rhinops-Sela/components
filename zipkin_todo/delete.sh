#!/bin/bash
NAMESPACE=zipkin
if kubectl get namespace $NAMESPACE; then
    kubectl delete namespace $NAMESPACE
fi