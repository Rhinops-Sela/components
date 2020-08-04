#!/bin/bash
NAMESPACE=kafka
RELEASE=kafka


if ! kubectl get namespace $NAMESPACE
then
  kubectl create namespace $NAMESPACE
  # install using helm
  helm repo add confluent https://confluentinc.github.io/cp-helm-charts/
  helm repo update
  helm install \
    $RELEASE \
    confluent/cp-helm-charts \
    -f values.yaml \
    --namespace $NAMESPACE \
    --wait
  kubectl apply -f deployment.yaml -n $NAMESPACE
  kubectl apply -f service.yaml -n $NAMESPACE
else
  echo $NAMESPACE exists
fi

#kafka-topics --zookeeper zookeeper.example.com:2181 --delete --topic 'gated12554ns-.*'