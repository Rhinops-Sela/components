#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/monitoring-nodegroup.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Set-Location -Path $PSScriptRoot
$workingFolder= "$PSScriptRoot"
$HelmChart = [HelmChart]::new(@{
  name = "grafana"
  namespace = "monitoring"
  workingFolder = $workingFolder
  nodeGroup = [MonitoringNodeGroup]::new($workingFolder)
  dnsTarget = "grafana.monitoring.svc.cluster.local"
})
$HelmChart.UninstallHelmChart()



<#
#If prev helm uninstall fails
kubectl delete PodSecurityPolicy grafana
kubectl delete PodSecurityPolicy grafana-test
kubectl delete clusterrole grafana-clusterrole
kubectl delete ClusterRoleBinding grafana-clusterrolebinding
#>