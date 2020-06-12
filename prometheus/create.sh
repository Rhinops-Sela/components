#!/bin/bash
NAMESPACE=prometheus
RELEASE=prometheus


if ! kubectl get namespace $NAMESPACE
then
  kubectl create namespace $NAMESPACE
  helm repo add stable https://kubernetes-charts.storage.googleapis.com
  helm repo update
  helm install \
      $RELEASE \
      stable/prometheus \
      -f values.yaml \
      -n $NAMESPACE \
      --dry-run
else
  echo $NAMESPACE exists
fi