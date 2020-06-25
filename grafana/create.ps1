#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/monitoring-nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'

#Create kubeconfig file
Write-Host "Grafana - PSScriptRoot: $PSScriptRoot"
$MonitoringNodeGroup = [MonitoringNodeGroup]::new($PSScriptRoot)
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
InstallHelmChart $helmChart
#>



