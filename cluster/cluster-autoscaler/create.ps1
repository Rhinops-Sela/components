#!/bin/pwsh
# Handling parameters
Write-Host "cluster-autoscaler.ps1"
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

$result = CreateKubeConfig -ClusterName $lookUpCluster -ClusterRegion $lookUpRegion -Nodegroup $nodegroupName -KubeConfigName ".kube"
$nodegroupName = 'system'
$result = ValidateNodeGroup -ClusterName $lookUpCluster -ClusterRegion $lookUpRegion -Nodegroup $nodegroupName
if (!$result) { return $false } # exit if nodegroup doesnt exist

$ns = "cluster-autoscaler"
$result = ValidateK8sObject -Namespace $ns -K8SObject "deployment/cluster-autoscaler-aws-cluster-autoscaler" -Nodegroup $nodegroupName -KubeConfigName ".kube"
if ($result) { return $false } #exit if object exist

$release = "cluster-autoscaler"
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
$result=CreateK8sNamespace -Namespace $ns -KubeConfigName ".kube"
if ($result) {
    helm install $release stable/cluster-autoscaler -f "./cluster-autoscaler/values.yaml$filepostfix" --namespace $ns --kubeconfig .kube --version 7.0.0 # newer versions require kubernetes 1.17 https://hub.helm.sh/charts/stable/cluster-autoscaler/7.0.0
}
