#!/bin/pwsh
$lookUpCluster = 'fennec-cluster'
$lookUpRegion = 'eu-west-1'
$lookUpNodegroup = 'system'

# check for cluster
$clusterExists = $false
$clustersList = eksctl get clusters -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
if ($clustersList -contains $lookUpCluster) {
    $clusterExists = $true
}

# handle cluster delete
if ($clusterExists) {
    Write-Host "cluster $lookUpCluster was found, deleting..."
    aws eks --region $lookUpRegion update-kubeconfig --name fennec-cluster
    # handle worker nodegroup
    $noderoupExists = $false
    $nodegroupList = eksctl get nodegroups --cluster $lookUpCluster -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
    if ($nodegroupList -contains $lookUpNodegroup) {
        $noderoupExists = $true
    }
    if ($noderoupExists) {
        Write-Host "nodegroup $lookUpNodegroup was found. deleting it."
        eksctl delete nodegroup -f ./nodegroups/system_node_group.yaml --approve
    }
    else {
        Write-Host "nodegroup $lookUpNodegroup was not found."
        
    }
    eksctl delete cluster -f ./cluster.yaml
}
else {
    Write-Host "cluster $lookUpCluster was not found"
}