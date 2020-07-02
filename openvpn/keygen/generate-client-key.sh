#!/bin/bash

if [ $# -ne 4 ]
then
  echo "Usage: $0 <NAMESPACE> <HELM_RELEASE> <USER_LIST> <OUTPUT_FOLDER>"
  exit
fi

USER_LIST=$1
NAMESPACE=$2
HELM_RELEASE=$3
OUTPUT_FOLDER=$4
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "app=openvpn,release=$HELM_RELEASE" -o jsonpath='{.items[0].metadata.name}')
SERVICE_NAME=$(kubectl get svc -n "$NAMESPACE" -l "app=openvpn,release=$HELM_RELEASE" -o jsonpath='{.items[0].metadata.name}')
SERVICE_IP=$(kubectl get svc -n "$NAMESPACE" "$SERVICE_NAME" -o go-template='{{range $k, $v := (index .status.loadBalancer.ingress 0)}}{{$v}}{{end}}')
for user in ${USER_LIST//,/$'\n'}
do
  KEY_NAME="${user//@/\.}"
  kubectl -n "$NAMESPACE" exec -it "$POD_NAME" -- /etc/openvpn/setup/newClientCert.sh "$KEY_NAME" "$SERVICE_IP"
  kubectl -n "$NAMESPACE" exec -it "$POD_NAME" -- cat "/etc/openvpn/certs/pki/$KEY_NAME.ovpn" > "$OUTPUT_FOLDER/$KEY_NAME.ovpn"
done