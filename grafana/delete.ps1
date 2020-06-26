#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/monitoring-nodegroup.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

Set-Location -Path $PSScriptRoot
$workingFolder= "$PSScriptRoot"
$HelmChart = [HelmChart]::new(@{
  name = "grafana"
  namespace = [Namespace]::new("monitoring", $workingFolder)
  workingFolder = $workingFolder
  nodeGroup = [MonitoringNodeGroup]::new($workingFolder)
  DNS = [CoreDNS]::new("grafana.monitoring.svc.cluster.local",$workingFolder)
})
$HelmChart.UninstallHelmChart()



<#
#If prev helm uninstall fails
kubectl delete PodSecurityPolicy grafana
kubectl delete PodSecurityPolicy grafana-test
kubectl delete clusterrole grafana-clusterrole
kubectl delete ClusterRoleBinding grafana-clusterrolebinding
#>