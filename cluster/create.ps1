#!/bin/pwsh

aws configure set aws_access_key_id $Env:AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $Env:AWS_SECRET_ACCESS_KEY
aws configure set region $Env:AWS_DEFAULT_REGION

# Handling parameters
if ($PSDebugContext){
    $lookUpCluster = 'fennec1'
    $lookUpRegion = 'eu-west-1'
    $lookUpAdminARN = 'arn:aws:iam::027065296145:user/iliag'
    $lookUpClusterDashboard = "$true"
    $lookUpClusterAutoscaler = "$true"
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

$nodegroupName = 'system'
$clusterExists = $false
$clustersList = eksctl get clusters -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
if ($clustersList -contains $lookUpCluster) {
    $clusterExists = $true
}

if ($clusterExists) {
    Write-Host "cluster $lookUpCluster was found, updating kubeconfig..."
    $result = CreateKubeConfig -ClusterName $lookUpCluster -ClusterRegion $lookUpRegion -Nodegroup $nodegroupName -KubeConfigName ".kube"
}
else {
    Write-Host "cluster $lookUpCluster was not found, creating..."
    eksctl create cluster -f "./cluster.yaml$filepostfix"
    $result = CreateNodegroup -NodegroupName "system" -Postfix "$filepostfix"
    $result = CreateKubeConfig -ClusterName $lookUpCluster -ClusterRegion $lookUpRegion -Nodegroup $nodegroupName -KubeConfigName ".kube"
    # coredns:tolerations
    $tolerations = (Get-Content ./coredns/tolerations.yaml -Raw)
    $tolerations = $tolerations.replace('"', '\"')
    Write-Host "patching coredns: tolerations"
    kubectl patch deployment/coredns -n kube-system --patch "$tolerations" --kubeconfig .kube

    # coredns:custom domain name
    $nameResolution = (Get-Content "./coredns/configmap.yaml$filepostfix" -Raw)
    $nameResolution = $nameResolution.replace('"', '\"')
    Write-Host "patching coredns: custom domain name"
    kubectl patch configmap/coredns -n kube-system --patch "$nameResolution" --kubeconfig .kube
    Write-Host "patching coredns: deleting pods to refresh.."
    kubectl delete pods -l k8s-app=kube-dns -n kube-system --kubeconfig .kube

    # aws-auth: admin user IAM
    $userName = ($lookUpAdminARN -split "/")[1]
    $awsAuth = (Get-Content "./aws/aws-auth.yaml$filepostfix" -Raw)
    $awsAuth = $awsAuth.replace('"', '\"')
    $awsAuth = $awsAuth.replace('${AWS_ADMIN_USER}', $userName)
    Write-Host "patching aws-auth: adding $userName ARN"
    kubectl patch configmap/aws-auth -n kube-system --patch "$awsAuth" --kubeconfig .kube

    # cluster dashboard
    if ($lookUpClusterDashboard) {
        $result = ./dashboard/create.ps1
    }

    # cluster autoscaler
    if ($lookUpClusterAutoscaler) {
        $result = ./cluster-autoscaler/create.ps1
    }

    # cluster autoscaler
    if ($lookUpHPA) {
        $result = ./horizontal-pod-scaler/create.ps1
    }
}
