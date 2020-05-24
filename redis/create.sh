#!/bin/bash
# from: https://bitnami.com/stack/redis/helm


NAMESPACE=redis
RELEASE=redis

if ! kubectl get namespace $NAMESPACE
then
  kubectl create namespace $NAMESPACE
  # install using helm
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update
  helm install \
    $RELEASE \
    bitnami/redis \
    -f values.yaml \
    --namespace $NAMESPACE \
    --wait

    #kubectl get secret --namespace redis redis -o jsonpath="{.data.redis-password}" | base64 --decode > ../../output/redis-admin-secret
    kubectl apply -f deployment.yaml -n $NAMESPACE
    kubectl apply -f service.yaml -n $NAMESPACE

else
  echo $NAMESPACE exists
fi


