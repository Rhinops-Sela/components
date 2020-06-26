#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/monitoring-nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

$workingFolder= "$PSScriptRoot"
Write-Host "Grafana - PSScriptRoot: $workingFolder"
$HelmChart = [HelmChart]::new(@{
  name = "grafana"
  chart = "stable/grafana"
  namespace = [Namespace]::new("monitoring", $workingFolder)
  repoUrl = "https://kubernetes-charts.storage.googleapis.com"
  valuesFilepath = "$workingFolder/values.yaml"
  workingFolder = $workingFolder
  nodeGroup = [MonitoringNodeGroup]::new($workingFolder)
  DNS = [CoreDNS]::new("grafana.monitoring.svc.cluster.local",$workingFolder)
})
$HelmChart.InstallHelmChart()


#kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode > ../../output/grafana-admin-secret




