#!/bin/bash
NAMESPACE=dynamodb

if kubectl get namespace $NAMESPACE; then
    kubectl delete namespace $NAMESPACE
fi