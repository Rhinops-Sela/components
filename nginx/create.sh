#!/bin/bash
NAMESPACE=ingress-nginx
RELEASE=controller


if ! kubectl get namespace $NAMESPACE
then
  kubectl create -f aws/deploy.yaml -n $NAMESPACE
else
  echo $NAMESPACE exists
fi
