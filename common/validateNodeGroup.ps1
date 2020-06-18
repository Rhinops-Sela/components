#!/bin/pwsh
#region Cluster
param (
    [Alias("ClusterName")] $lookUpCluster,
    [Alias("NodegroupName")]  $nodegroup
)

$noderoupExists = $false
$nodegroupList = eksctl get nodegroups --cluster $lookUpCluster -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
if ($nodegroupList -contains $nodegroup) {
    $noderoupExists = $true
}

if ($noderoupExists) {
    Write-Host "nodegroup $nodegroup was found."
    return $true
}
else {
    Write-Error "nodegroup $nodegroup was not found"
    return $false
}
    #endregion ClusteR