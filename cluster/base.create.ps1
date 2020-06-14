#!/bin/pwsh
$lookUpCluster = '${CLUSTER_NAME}'
$lookUpRegion = '${AWS_REGION}'
$lookUpAdminARN = '${AWS_ADMIN_ARN}'
$lookUpNodegroup = 'system'

#region Cluster
$clusterExists = $false

$clustersList = eksctl get clusters -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
if ($clustersList -contains $lookUpCluster) {
    $clusterExists = $true
}

if ($clusterExists) {
    Write-Host "cluster $lookUpCluster was found, updating kubeconfig..."    
    aws eks --region $lookUpRegion update-kubeconfig --name $lookUpCluster
}
else {
    Write-Host "cluster $lookUpCluster was not found, creating..."
    eksctl create cluster -f ./cluster.yaml
}
#endregion Cluster

#region Nodegroups
$noderoupExists = $false
$nodegroupList = eksctl get nodegroups --cluster $lookUpCluster -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
if ($nodegroupList -contains $lookUpNodegroup) {
    $noderoupExists = $true
}

if ($noderoupExists) {
    Write-Host "nodegroup $lookUpNodegroup was found. SKIPPING."
}
else {
    Write-Host "nodegroup $lookUpNodegroup was not found, creating it"
    eksctl create nodegroup -f ./nodegroups/system_node_group.yaml
}
#endregion Nodegroups

#region Configuration
# coredns:tolerations
$tolerations = (Get-Content ./coredns/tolerations.yaml -Raw)
$tolerations = $tolerations.replace('"', '\"')
Write-Host "patching coredns: tolerations"
kubectl patch deployment/coredns -n kube-system --patch "$tolerations"

# coredns:custom domain name
$nameResolution = (Get-Content ./coredns/configmap.yaml -Raw)
$nameResolution = $nameResolution.replace('"', '\"')
$nameResolution = $nameResolution.replace('${CUSTOM_DOMAIN_NAME}', $lookupCustomDomainName)
Write-Host "patching coredns: custom domain name"
kubectl patch configmap/coredns -n kube-system --patch "$nameResolution"
Write-Host "patching coredns: deleting pods to refresh.."
kubectl delete pods -l k8s-app=kube-dns -n kube-system

# aws-auth: admin user IAM
$userName = ($lookUpAdminARN -split "/")[1]
$awsAuth = (Get-Content ./aws-auth.yaml -Raw)
$awsAuth = $awsAuth.replace('"', '\"')
$awsAuth = $awsAuth.replace('${AWS_ADMIN_ARN}', $lookUpAdminARN)
$awsAuth = $awsAuth.replace('${AWS_ADMIN_USER}', $userName)
Write-Host "patching aws-auth: adding $userName ARN"
kubectl patch configmap/aws-auth -n kube-system --patch "$awsAuth"
#endregion Configuration