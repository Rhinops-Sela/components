#!/bin/bash
# https://hub.helm.sh/charts/stable/cluster-autoscaler/7.2.2

NAMESPACE=cluster-autoscaler
RELEASE=cluster-autoscaler

# create namespace
if ! kubectl get namespace $NAMESPACE
then
  kubectl create namespace $NAMESPACE
  #install using helm
  helm repo add stable https://kubernetes-charts.storage.googleapis.com
  helm repo update
  helm install \
    $RELEASE \
    stable/cluster-autoscaler \
    -f values.yaml \
    --namespace $NAMESPACE \
    --version 7.0.0 # newer versions require kubernetes 1.17 https://hub.helm.sh/charts/stable/cluster-autoscaler/7.0.0
else
  echo $NAMESPACE exists
fi