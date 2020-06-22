#!/bin/pwsh

aws configure set aws_access_key_id $Env:AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $Env:AWS_SECRET_ACCESS_KEY
aws configure set region $Env:AWS_DEFAULT_REGION
Write-Host "Cluster Component Started"
# Handling parameters
if ($PSDebugContext){
    $lookUpCluster = 'fennec'
    $lookUpRegion = 'eu-west-1'
    $lookUpAdminARN = 'arn:aws:iam::027065296145:user/iliag'
    $lookUpClusterDashboard = "$true"
    $lookUpClusterAutoscaler = "$true"
    $lookUpHPA = "$true"
    $filepostfix = '.ydebug'
}
else {
    $lookUpCluster = '${CLUSTER_NAME}'
    $lookUpRegion = '${CLUSTER_REGION}'
    $lookUpAdminARN = '${CLUSTER_ADMIN_ARN}'
    $lookUpClusterDashboard = "${DASHBOARD}"
    $lookUpClusterAutoscaler = "${CLUSTER_AUTO_SCALE}"
    $lookUpHPA = "${POD_HORIZONTAL_AUTO_SCALE}"
    $filepostfix = ''
}

. ../common/helper.ps1

$clusterExists = $false
$clustersList = Retry-Command -ScriptBlock {
    eksctl get clusters -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
}
if ($clustersList -contains $lookUpCluster) {
    $clusterExists = $true
}

if ($clusterExists) {
    Write-Information "cluster $lookUpCluster was found, updating kubeconfig..." -InformationAction Continue
    CreateKubeConfig -cluster $lookUpCluster -region $lookUpRegion -kubePath ".kube" | Out-Null
}
else {
    # cluster: create 
    Write-Information "cluster $lookUpCluster was not found, creating..." -InformationAction Continue
    Retry-Command -ScriptBlock {
        eksctl create cluster -f "./cluster.yaml$filepostfix" | Out-Null
    }
    CreateNodegroup -cluster $lookUpCluster -nodegroup "system" -filePostfix "$filepostfix" | Out-Null
    CreateKubeConfig -cluster $lookUpCluster -region $lookUpRegion -kubePath ".kube" | Out-Null
    
    # coredns:tolerations
    $tolerations = (Get-Content ./coredns/tolerations.yaml -Raw)
    $tolerations = $tolerations.replace('"', '\"')
    Write-Information "patching coredns: tolerations" -InformationAction Continue
    Retry-Command -ScriptBlock {
        kubectl patch deployment/coredns -n kube-system --patch "$tolerations" --kubeconfig .kube
    } | Out-Null

    # coredns:custom domain name
    $nameResolution = (Get-Content "./coredns/configmap.yaml$filepostfix" -Raw)
    $nameResolution = $nameResolution.replace('"', '\"')
    Write-Information "patching coredns: custom domain name" -InformationAction Continue
    Retry-Command -ScriptBlock {
        kubectl patch configmap/coredns -n kube-system --patch "$nameResolution" --kubeconfig .kube 
    } | Out-Null
    Write-Information "patching coredns: deleting pods to refresh.." -InformationAction Continue
    Retry-Command -ScriptBlock {
        kubectl delete pods -l k8s-app=kube-dns -n kube-system --kubeconfig .kube
    } | Out-Null

    # aws-auth: admin user IAM
    $userName = ($lookUpAdminARN -split "/")[1]
    $awsAuth = (Get-Content "./aws/aws-auth.yaml$filepostfix" -Raw)
    $awsAuth = $awsAuth.replace('"', '\"')
    $awsAuth = $awsAuth.replace('${CLUSTER_ADMIN_USER}', $userName)
    Write-Information "patching aws-auth: adding $userName ARN" -InformationAction Continue
    Retry-Command -ScriptBlock {
        kubectl patch configmap/aws-auth -n kube-system --patch "$awsAuth" --kubeconfig .kube
    } | Out-Null

    # cluster autoscaler
    if ($lookUpClusterAutoscaler) {
        $result = ./cluster-autoscaler/create.ps1
    }
    
    # cluster autoscaler
    if ($lookUpHPA) {
        $result = ./horizontal-pod-scaler/create.ps1
    }
    
    # cluster dashboard
    if ($lookUpClusterDashboard) {
        $result = ./dashboard/create.ps1
    }
}