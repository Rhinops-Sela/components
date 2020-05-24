#https://itnext.io/use-helm-to-deploy-openvpn-in-kubernetes-to-access-pods-and-services-217dec344f13

#!/bin/bash
NAMESPACE=openvpn
RELEASE=openvpn
KEY_NAME=fg-frankfurt
KEY_NAME=fg-frankfurt

if ! kubectl get namespace $NAMESPACE
then
  kubectl create namespace $NAMESPACE
  kubectl create -f openvpn-pv-claim.yaml -n $NAMESPACE
  #install using helm
  helm repo add stable http://storage.googleapis.com/kubernetes-charts
  helm repo update
  helm install \
    $RELEASE \
    stable/openvpn \
    -n $NAMESPACE \
    -f values.yaml \
    --wait
  ./generate-client-key.sh $KEY_NAME $NAMESPACE $RELEASE
  ./generate-client-key.sh $KEY_NAME $NAMESPACE $RELEASE
else
  echo $NAMESPACE exists
fi

./generate-client-key.sh hanan openvpn openvpn