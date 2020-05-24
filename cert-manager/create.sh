#!/bin/bash
# https://hub.helm.sh/charts/jetstack/cert-manager/v0.15.0

NAMESPACE=cert-manager
RELEASE=cert-manager

if ! kubectl get namespace $NAMESPACE
then
  kubectl create namespace $NAMESPACE
  # install using helm
  helm repo add jetstack https://charts.jetstack.io
  helm repo update
  helm install \
    $RELEASE \
    jetstack/cert-manager \
    -f values.yaml \
    --namespace $NAMESPACE \
    --wait

  ## apply issuers
  sleep 30s # https://github.com/jetstack/cert-manager/issues/2602#issuecomment-625555544
  kubectl apply -f ./letsencrypt-cluster-issuers.yaml
  kubectl apply -f ./selfsigned-cluster-issuer.yaml
else
  echo $NAMESPACE exists
fi