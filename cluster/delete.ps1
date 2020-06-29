#!/bin/pwsh
# Handling parameters
if ($DebugPreferences -eq "Continue"){
    $lookUpCluster = 'fennec-cluster'
    $lookUpRegion = 'eu-west-1'
    $filepostfix = '.ydebug'
}
else {
    $lookUpCluster = '${GLOBAL_CLUSTER_NAME}'
    $lookUpRegion = '${GLOBAL_CLUSTER_REGION}'
    $filepostfix = ''
}
$nodegroupName = 'system'

# check for cluster
$clusterExists = $false
$clustersList = eksctl get clusters -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
if ($clustersList -contains $lookUpCluster) {
    $clusterExists = $true
}

# handle cluster delete
if ($clusterExists) {
    Write-Host "cluster $lookUpCluster was found, deleting..."
    aws eks --region $lookUpRegion update-kubeconfig --name $lookUpCluster --kubeconfig .kube
    # handle worker nodegroup
    $noderoupExists = $false
    $nodegroupList = eksctl get nodegroups --cluster $lookUpCluster -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
    if ($nodegroupList -contains $nodegroupName) {
        $noderoupExists = $true
    }
    if ($noderoupExists) {
        Write-Host "nodegroup $nodegroupName was found. deleting it."
        eksctl delete nodegroup -f "./nodegroups/system_node_group.yaml$filepostfix" --approve
    }
    else {
        Write-Host "nodegroup $nodegroupName was not found."
    }
    eksctl delete cluster -f "./cluster.yaml$filepostfix"
}
else {
    Write-Host "cluster $lookUpCluster was not found"
}