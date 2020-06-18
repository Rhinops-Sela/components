#!/bin/pwsh

pwd
aws configure set default.aws_access_key_id '' --profile default
Write-Host "here"


# Handling parameters
if ($PSDebugContext){
    $lookUpCluster = 'bubu-cluster'
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
    $lookUpClusterDashboard = "${CLUSTER_DASHBOARD}"
    $lookUpClusterAutoscaler = "${CLUSTER_HORIZONTAL_AUTO_SCALE}"
    $filepostfix = ''
}
$nodegroupName = 'system'
$clusterExists = $false
$clustersList = eksctl get clusters -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
if ($clustersList -contains $lookUpCluster) {
    $clusterExists = $true
}

if ($clusterExists) {
    Write-Host "cluster $lookUpCluster was found, updating kubeconfig..."
    aws eks --region $lookUpRegion update-kubeconfig --name $lookUpCluster --kubeconfig /home/noama/dev/rhinops/components/cluster/.kube
}
else {
    Write-Host "cluster $lookUpCluster was not found, creating..."
    eksctl create cluster -f "../components/cluster/cluster.yaml$filepostfix"

    #region Nodegroups
    $noderoupExists = $false
    $nodegroupList = eksctl get nodegroups --cluster $lookUpCluster -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
    if ($nodegroupList -contains $nodegroupName) {
        $noderoupExists = $true
    }

    if ($noderoupExists) {
        Write-Host "nodegroup $nodegroupName was found. SKIPPING."
    }
    else {
        Write-Host "nodegroup $nodegroupName was not found, creating it"
        eksctl create nodegroup -f "../components/cluster/nodegroups/system_node_group.yaml$filepostfix"
    }
    #endregion Nodegroups

    #region Configuration
    # coredns:tolerations
    $tolerations = (Get-Content ../components/cluster/coredns/tolerations.yaml -Raw)
    $tolerations = $tolerations.replace('"', '\"')
    Write-Host "patching coredns: tolerations"
    kubectl patch deployment/coredns -n kube-system --patch "$tolerations" --kubeconfig ../components/cluster/.kube

    # coredns:custom domain name
    $nameResolution = (Get-Content "../components/cluster/coredns/configmap.yaml$filepostfix" -Raw)
    $nameResolution = $nameResolution.replace('"', '\"')
    Write-Host "patching coredns: custom domain name"
    kubectl patch configmap/coredns -n kube-system --patch "$nameResolution" --kubeconfig ../components/cluster/.kube
    Write-Host "patching coredns: deleting pods to refresh.."
    kubectl delete pods -l k8s-app=kube-dns -n kube-system --kubeconfig ../components/cluster/.kube

    # aws-auth: admin user IAM
    $userName = ($lookUpAdminARN -split "/")[1]
    $awsAuth = (Get-Content "../components/cluster/aws/aws-auth.yaml$filepostfix" -Raw)
    $awsAuth = $awsAuth.replace('"', '\"')
    $awsAuth = $awsAuth.replace('${AWS_ADMIN_USER}', $userName)
    Write-Host "patching aws-auth: adding $userName ARN"
    kubectl patch configmap/aws-auth -n kube-system --patch "$awsAuth" --kubeconfig ../components/cluster/.kube
    #endregion Configuration

    # cluster autoscaler
    if ($lookUpClusterDashboard) {
        ../components/cluster/dashboard/create.ps1
    }

    # cluster autoscaler
    if ($lookUpClusterAutoscaler) {
        ../components/cluster/create.ps1
    }
}