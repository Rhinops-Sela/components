#!/bin/bash
NAMESPACE=openvpn
RELEASE=openvpn
KEY_NAME=openvpn


if kubectl get namespace $NAMESPACE; then
  helm uninstall $RELEASE -n $NAMESPACE
  kubectl delete namespace $NAMESPACE
  rm ../../output/*.ovpn
fi
