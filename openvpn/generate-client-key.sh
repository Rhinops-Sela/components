#!/bin/bash

if [ $# -ne 3 ]
then
  echo "Usage: $0 <CLIENT_KEY_NAME> <NAMESPACE> <HELM_RELEASE>"
  exit
fi

KEY_NAME=$1
NAMESPACE=$2
HELM_RELEASE=$3
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "app=openvpn,release=$HELM_RELEASE" -o jsonpath='{.items[0].metadata.name}')
SERVICE_NAME=$(kubectl get svc -n "$NAMESPACE" -l "app=openvpn,release=$HELM_RELEASE" -o jsonpath='{.items[0].metadata.name}')
SERVICE_IP=$(kubectl get svc -n "$NAMESPACE" "$SERVICE_NAME" -o go-template='{{range $k, $v := (index .status.loadBalancer.ingress 0)}}{{$v}}{{end}}')


usersList="noama@sela.co.il;iliag@sela.co.il;shlomo.idov@sela.co.il"
for user in ${usersList//;/$'\n'}
do
  KEY_NAME="${user//@/\.}"
  kubectl -n "$NAMESPACE" exec -it "$POD_NAME" -- /etc/openvpn/setup/newClientCert.sh "$KEY_NAME" "$SERVICE_IP"
  kubectl -n "$NAMESPACE" exec -it "$POD_NAME" -- cat "/etc/openvpn/certs/pki/$KEY_NAME.ovpn" > ../../output/"$KEY_NAME.ovpn" 
done