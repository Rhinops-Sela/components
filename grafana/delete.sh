#!/bin/bash
NAMESPACE=grafana
RELEASE=grafana


if kubectl get namespace $NAMESPACE; then
  helm uninstall $RELEASE -n $NAMESPACE
  kubectl delete namespace $NAMESPACE

  rm ../../output/grafana-admin-secret
fi
