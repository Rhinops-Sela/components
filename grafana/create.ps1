#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
$debug='${DNS_RECORD}'
if ($debug -Match 'DNS_RECORD'){
    $requestedUrl = 'grafna.fennec.io'
    $clusterName = "fennec"
    $clusterRegion = "eu-west-2"
    $debugPrefix = ".debug"
}
else {
    aws configure set aws_access_key_id $Env:AWS_ACCESS_KEY_ID
    aws configure set aws_secret_access_key $Env:AWS_SECRET_ACCESS_KEY
    aws configure set region $Env:AWS_DEFAULT_REGION
    $requestedUrl = '${DNS_RECORD}'
    $clusterName = $Env:CLUSTER_NAME
    $clusterRegion = $Env:CLUSTER_REGION
}




#Create kubeconfig file
aws eks update-kubeconfig --name $clusterName --region $clusterRegion --kubeconfig $PSScriptRoot/.kube

$MonitoringNodeGroup = [MonitoringNodeGroup]::new($clusterName, $clusterRegion, $PSScriptRoot, $debugPrefix)
$MonitoringNodeGroup.CreateNodeGroup()
$Namespace = [Namespace]::new("monitoring", "$($PSScriptRoot)/.kube")
$Namespace.CreateNamespace()

<#
  $NAMESPACE = "monitoring"
  $helmChart = @{
  name = "grafana"
  chart = "stable/grafana"
  namespace = "$NAMESPACE"
  repoUrl = "https://kubernetes-charts.storage.googleapis.com"
  valuesFilepath = "$PSScriptRoot/values.yaml"
}
CreateNamespace "$NAMESPACE" ".kube"#>
#InstallHelmChart $helmChart


