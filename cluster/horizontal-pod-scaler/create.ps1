#!/bin/pwsh
# Handling parameters
Write-Host "horizontal-pod-scaler.ps1"
if ($PSDebugContext){
    $lookUpCluster = 'fennec'
    $lookUpRegion = 'eu-west-1'}
else {
    $lookUpCluster = '${GLOBAL_CLUSTER_NAME}'
    $lookUpRegion = '${GLOBAL_CLUSTER_REGION}'
}
. ../common/helper.ps1

$result=CreateKubeConfig -cluster $lookUpCluster -region $lookUpRegion -kubePath .kube
$nodegroupName = 'system'
$result=ValidateNodeGroup -cluster $lookUpCluster -nodegroup $nodegroupName
if (!$result) { 
    Write-Error "nodegroup $nodegroupName doesnt exist, exiting"
    return $false 
} # exit if nodegroup doesnt exist

$ns="horizontal-pod-scaler"
$result = ValidateK8SObject -Namespace $ns -Object "deployment/metrics-server" -kubePath .kube
if ($result) { 
    Write-Information "deployment/horizontal-pod-scaler exist, exiting" -InformationAction Continue
    return $false 
} #exit if object already exist

kubectl create namespace $ns --kubeconfig .kube
kubectl apply -f ./horizontal-pod-scaler/hpa.yaml  --kubeconfig .kube
Write-Information "hpa installed" -InformationAction Continue