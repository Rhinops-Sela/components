#!/bin/bash


NAMESPACE=elasticsearch
RELEASE=elasticsearch

if kubectl get namespace $NAMESPACE; then
    helm uninstall $RELEASE -n $NAMESPACE 
    kubectl delete namespace $NAMESPACE

fi