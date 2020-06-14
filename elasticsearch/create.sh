#!/bin/bash
# from: https://hub.helm.sh/charts/elastic/elasticsearch
echo "falling a sleep -es"
sleep 1
echo "woke - es"
echo "test replacement: ${ES_CLUSTER_NAME}"
NAMESPACE=elasticsearch
RELEASE=elasticsearch

# create namespace
if ! kubectl get namespace $NAMESPACE
then
  kubectl create namespace $NAMESPACE
  helm install \
    $RELEASE \
    helm/elasticsearch \
    -f helm/elasticsearch/values.yaml \
    --namespace $NAMESPACE \
    --dry-run
else
  echo $NAMESPACE exists
fi
