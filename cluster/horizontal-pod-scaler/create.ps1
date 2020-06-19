#!/bin/pwsh
# Handling parameters
Write-Host "horizontal-pod-scaler.ps1"
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

$result=CreateKubeConfig -ClusterName $lookUpCluster -ClusterRegion $lookUpRegion -Nodegroup $nodegroupName -KubeConfigName .kube
$nodegroupName = 'system'
$result=ValidateNodeGroup -ClusterName $lookUpCluster -ClusterRegion $lookUpRegion -Nodegroup $nodegroupName
if (!$result) { return $false } # exit if nodegroup doesnt exist

$ns="horizontal-pod-scaler"
$result = ValidateK8SObject -Namespace $ns -K8SObject "deployment/horizontal-pod-scaler" -Nodegroup $nodegroupName -KubeConfigName .kube
if ($result) { return $false } #exit if object already exist

kubectl create namespace $ns --kubeconfig .kube
kubectl apply -f ./horizontal-pod-scaler/hpa.yaml  --kubeconfig .kube