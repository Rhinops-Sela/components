#!/bin/pwsh
# Handling parameters
Write-Host "dashboard.ps1"
Write-Host (Get-Location)
if ($PSDebugContext){
    $lookUpCluster = 'fennec-cluster'
    $lookUpRegion = 'eu-west-1'
    $filepostfix = '.ydebug'
}
else {
    $lookUpCluster = '${CLUSTER_NAME}'
    $lookUpRegion = '${CLUSTER_REGION}'
    $filepostfix = ''
}
$kubeConfigFile="/.kube"
../../common/createKubeConfig.ps1 -ClusterName $lookUpCluster -ClusterRegion $lookUpRegion -YamlPostfix $filepostfix -Nodegroup $nodegroupName -KubeConfigFullPath $kubeConfigFile
#$kubeConfigFile=(Get-Item -Path ".\").FullName+"/.kube"

$nodegroupName = 'system'
$result=../../common/validateNodeGroup.ps1 -ClusterName $lookUpCluster -ClusterRegion $lookUpRegion -YamlPostfix $filepostfix -Nodegroup $nodegroupName
if (!$result) { return $false } # exit if nodegroup doesnt exist

$ns="kubernetes-dashboard"
$result =../../common/validateK8sObject.ps1 -Namespace $ns -K8SObject "deployment/kubernetes-dashboard" -YamlPostfix $filepostfix -Nodegroup $nodegroupName -KubeConfigFullName $kubeConfigFile
if ($result) { return $false } #exit if object already exist

kubectl apply -f dashboard
New-Item -ItemType Directory -Force -Path ../../output > $null
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}') > ../../output/dashboard-admin-secret
