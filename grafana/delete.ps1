#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/monitoring-nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'
Set-Location -Path $PSScriptRoot
$workingFolder= "$PSScriptRoot"
$HelmChart = [HelmChart]::new(@{
  name = "grafana"
  namespace = "monitoring"
  workingFolder = $workingFolder
})
$HelmChart.UninstallHelmChart()
$Namespace = [Namespace]::new("monitoring", $workingFolder)
$Namespace.DeleteNamespace()
$MonitoringNodeGroup = [MonitoringNodeGroup]::new($workingFolder)
$MonitoringNodeGroup.DeleteNodeGroup()

<# kubectl delete  PodSecurityPolicy grafan
kubectl delete clusterrole grafana-clusterrole
kubectl delete ClusterRoleBinding grafana-clusterrolebinding #>