#!/bin/bash
NAMESPACE=grafana
RELEASE=grafana

if ! kubectl get namespace $NAMESPACE
then
  kubectl create namespace $NAMESPACE
  helm repo add stable https://kubernetes-charts.storage.googleapis.com
  helm repo update
  helm install \
      $RELEASE \
      stable/grafana \
      -f values.yaml \
      -n $NAMESPACE

  kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode > ../../output/grafana-admin-secret
else
  echo $NAMESPACE exists
fi