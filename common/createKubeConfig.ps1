#!/bin/pwsh
#region Cluster
param (
    [Alias("ClusterName")] $lookUpCluster,
    [Alias("ClusterRegion")] $lookUpRegion,
    [Alias("YamlPostfix")]  $filepostfix,
    [Alias("Nodegroup")]  $nodegroupName, 
    [Alias("KubeConfigFullPath")] $kubePath
)
$clusterExists = $false

$clustersList = eksctl get clusters -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
if ($clustersList -contains $lookUpCluster) {
    $clusterExists = $true
}

if ($clusterExists) {
    Write-Host "cluster $lookUpCluster was found, updating kubeconfig..."    
    aws eks --region $lookUpRegion update-kubeconfig --name $lookUpCluster --kubeconfig "$kubePath/.kube"
}
else {
    Write-Error "cluster $lookUpCluster was not found"
    exit 1
}