#!/bin/pwsh
#region Cluster
param (
    [Alias("Namespace")] $ns,
    [Alias("KubeConfigName")] $kubePath
)

$namespaces = kubectl get namespaces --kubeconfig "$kubePath"
$namespaceExists=$false

foreach ($namespace in $namespaces) {
    if ($namespace -match $ns) { return $true }
}
kubectl create namespace $ns --kubeconfig "$kubePath"
return $true