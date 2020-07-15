#!/bin/pwsh
# Handling parameters
Write-Host "dashboard.ps1"
if ($PSDebugContext){
    $lookUpCluster = 'fennec'
    $lookUpRegion = 'eu-west-1'
    $outputFolder = $Env:OUTPUT_FOLDER
}
else {
    $lookUpCluster = '${GLOBAL_CLUSTER_NAME}'
    $lookUpRegion = '${GLOBAL_CLUSTER_REGION}'
    $outputFolder = "$workingFolder/../outputs"
}
. ../common/helper.ps1

$result=CreateKubeConfig -cluster $lookUpCluster -region $lookUpRegion -kubePath ".kube"
$nodegroupName = 'system'
$result=ValidateNodegroup -cluster $lookUpCluster -nodegroup $nodegroupName
if (!$result) { 
    Write-Error "nodegroup $nodegroupName doesnt exist, exiting"
    return $false 
} # exit if nodegroup doesnt exist

$ns="kubernetes-dashboard"
$result = ValidateK8SObject -namespace $ns -Object "deployment/kubernetes-dashboard" -kubePath .kube
if ($result) {
    Write-Information "deployment/kubernetes-dashboard exist, exiting" -InformationAction Continue
    return $false 
} #exit if object already exist
kubectl apply -f ./dashboard/dashboard
New-Item -ItemType Directory -Force -Path ./output > $null
kubectl -n kube-system describe secret --kubeconfig .kube $(kubectl -n kube-system get secret --kubeconfig .kube | grep admin-user | awk '{print $1}') > "$outputFolder/dashboard.out"
Write-Information "dashboard installed" -InformationAction Continue