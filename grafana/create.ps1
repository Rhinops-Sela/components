#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/monitoring-nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

$workingFolder= "$PSScriptRoot"
Write-Host "Grafana - PSScriptRoot: $workingFolder"
$MonitoringNodeGroup = [MonitoringNodeGroup]::new($workingFolder)
$MonitoringNodeGroup.CreateNodeGroup()
$Namespace = [Namespace]::new("monitoring", $workingFolder)
$Namespace.CreateNamespace()

$HelmChart = [HelmChart]::new(@{
  name = "grafana"
  chart = "stable/grafana"
  namespace = "monitoring"
  repoUrl = "https://kubernetes-charts.storage.googleapis.com"
  valuesFilepath = "$workingFolder/values.yaml"
  workingFolder = $workingFolder
})
$HelmChart.InstallHelmChart()

$Namespace = [CoreDNS]::new("grafana.monitoring.svc.cluster.local",$workingFolder)
$Namespace.AddEntry()
#kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode > ../../output/grafana-admin-secret




