#!/bin/bash

NAMESPACE=kibana

if kubectl get namespace $NAMESPACE; then
  kubectl delete namespace $NAMESPACE
fi
