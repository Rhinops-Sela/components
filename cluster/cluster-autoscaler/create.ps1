#!/bin/pwsh
# Handling parameters
Write-Host "cluster-autoscaler.ps1"
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

$result = CreateKubeConfig -cluster $lookUpCluster -region $lookUpRegion -kubePath ".kube"
$nodegroupName = 'system'
$result = ValidateNodegroup -cluster $lookUpCluster -nodegroup $nodegroupName
if (!$result) {
    Write-Error "nodegroup $nodegroupName doesnt exist, exiting"
    return $false 
} # exit if nodegroup doesnt exist

$ns = "cluster-autoscaler"
$result = ValidateK8SObject -namespace $ns -Object "deployment/cluster-autoscaler-aws-cluster-autoscaler" -kubePath ".kube"
if ($result) { 
    Write-Information "deployment/cluster-autoscaler-aws-cluster-autoscaler exist, exiting" -InformationAction Continue
    return $false 
} #exit if object exist

$release = "cluster-autoscaler"
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
$result=CreateK8SNamespace -namespace $ns -kubePath ".kube"
if ($result) {
    helm install $release stable/cluster-autoscaler -f "./cluster-autoscaler/values.yaml$filepostfix" --namespace $ns --kubeconfig .kube --version 7.0.0 # newer versions require kubernetes 1.17 https://hub.helm.sh/charts/stable/cluster-autoscaler/7.0.0
}
