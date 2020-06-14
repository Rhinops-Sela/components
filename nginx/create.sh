#!/bin/bash
NAMESPACE=ingress-nginx
RELEASE=controller
echo "falling a sleep -nginx"
sleep 1
echo "woke -nginx"

if ! kubectl get namespace $NAMESPACE
then
  kubectl create -f aws/deploy.yaml -n $NAMESPACE
else
  echo $NAMESPACE exists
fi
