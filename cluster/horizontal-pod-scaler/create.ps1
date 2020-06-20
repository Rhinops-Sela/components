#!/bin/pwsh
# Handling parameters
Write-Host "horizontal-pod-scaler.ps1"
if ($PSDebugContext){
    $lookUpCluster = 'fennec'
    $lookUpRegion = 'eu-west-1'
    $filepostfix = '.ydebug'
}
else {
    $lookUpCluster = '${CLUSTER_NAME}'
    $lookUpRegion = '${CLUSTER_REGION}'
    $filepostfix = ''
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
$result = ValidateK8SObject -Namespace $ns -Object "deployment/horizontal-pod-scaler" -kubePath .kube
if ($result) { 
    Write-Information "deployment/horizontal-pod-scaler exist, exiting" -InformationAction Continue
    return $false 
} #exit if object already exist

kubectl create namespace $ns --kubeconfig .kube
kubectl apply -f ./horizontal-pod-scaler/hpa.yaml  --kubeconfig .kube