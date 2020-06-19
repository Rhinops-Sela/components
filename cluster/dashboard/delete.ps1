#!/bin/pwsh
# Handling parameters
if ($PSDebugContext -eq "Continue"){
    $lookUpCluster = 'fennec1'
    $lookUpRegion = 'eu-west-1'
}
else {
    $lookUpCluster = '${CLUSTER_NAME}'
    $lookUpRegion = '${CLUSTER_REGION}'
}

# check for cluster
$clusterExists = $false
$clustersList = eksctl get clusters -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
if ($clustersList -contains $lookUpCluster) {
    $clusterExists = $true
}

# handle cluster delete
if ($clusterExists) {
    Write-Host "cluster $lookUpCluster was found, updating kubeconfig"
    aws eks --region $lookUpRegion update-kubeconfig --name $lookUpCluster --kubeconfig .kube
    
    $namespace="cluster-autoscaler"
    $release="cluster-autoscaler"
    helm uninstall $release -n $namespace
}
else {
    Write-Error "cluster $lookUpCluster was not found"
    return $false
}