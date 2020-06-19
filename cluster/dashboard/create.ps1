#!/bin/pwsh
# Handling parameters
Write-Host "dashboard.ps1"
if ($PSDebugContext){
    $lookUpCluster = 'fennec1'
    $lookUpRegion = 'eu-west-1'
    $filepostfix = '.ydebug'
}
else {
    $lookUpCluster = '${CLUSTER_NAME}'
    $lookUpRegion = '${CLUSTER_REGION}'
    $filepostfix = ''
}
. ../common/helper.ps1

$result=CreateKubeConfig -ClusterName $lookUpCluster -ClusterRegion $lookUpRegion -Nodegroup $nodegroupName -KubeConfigName ".kube"
$nodegroupName = 'system'
$result=ValidateNodeGroup -ClusterName $lookUpCluster -ClusterRegion $lookUpRegion -Nodegroup $nodegroupName
if (!$result) { return $false } # exit if nodegroup doesnt exist

$ns="kubernetes-dashboard"
$result = ValidateK8SObject -Namespace $ns -K8SObject "deployment/kubernetes-dashboard" -Nodegroup $nodegroupName -KubeConfigName .kube
if ($result) { return $false } #exit if object already exist

kubectl apply -f ./dashboard/dashboard
New-Item -ItemType Directory -Force -Path ./output > $null
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}') > ./output/dashboard-admin-secret
