#!/bin/pwsh
# Handling parameters
if (! $PSDebugContext){
    $lookUpCluster = 'fennec-cluster'
    $lookUpRegion = 'eu-west-1'
    $filepostfix = '.ydebug'
}
else {
    $lookUpCluster = '${CLUSTER_NAME}'
    $lookUpRegion = '${CLUSTER_REGION}'
    $filepostfix = ''
}

../../common/createKubeConfig.ps1 -ClusterName $lookUpCluster -ClusterRegion $lookUpRegion -YamlPostfix $filepostfix -Nodegroup $nodegroupName -KubeConfigFullPath (Get-Item -Path ".\").FullName
$kubeConfigFile=(Get-Item -Path ".\").FullName+"/.kube"

$nodegroupName = 'system'
$result=../../common/validateNodeGroup.ps1 -ClusterName $lookUpCluster -ClusterRegion $lookUpRegion -YamlPostfix $filepostfix -Nodegroup $nodegroupName
if (!$result) { return $false } # exit if nodegroup doesnt exist

$ns="cluster-autoscaler"
$result =../../common/validateK8sObject.ps1 -Namespace $ns -K8SObject "deployment/cluster-autoscaler-aws-cluster-autoscaler" -YamlPostfix $filepostfix -Nodegroup $nodegroupName -KubeConfigFullName $kubeConfigFile
if ($result) { return $false } #exit if object exist

$release="cluster-autoscaler"
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
$result= Invoke-Expression "$PSScriptRoot/createK8sNamespace.ps1 -Namespace $ns -KubeConfigFullName $kubePath"
if ($result) {
    helm install $release stable/cluster-autoscaler -f "values.yaml$filepostfix" --namespace $ns --kubeconfig .kube --version 7.0.0 # newer versions require kubernetes 1.17 https://hub.helm.sh/charts/stable/cluster-autoscaler/7.0.0
}
