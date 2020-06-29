#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/monitoring-nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

$workingFolder= "$PSScriptRoot"
$executeValuesFilepath= "$workingFolder/values-execute.json"
Write-Host "DD - PSScriptRoot: $workingFolder"
$HelmChart = [HelmChart]::new(@{
  name = "datadog"
  chart = "stable/datadog"
  namespace = [Namespace]::new("monitoring", $workingFolder)
  valuesFilepath = "$executeValuesFilepath"
  workingFolder = $workingFolder
  nodeGroup = [MonitoringNodeGroup]::new($workingFolder)
})
$apiKey = "${DD_API_KEY}"
$appKey = "${DD_APP_KEY}"
if($HelmChart.debug){
  $apiKey = "dd-fennec-api-key"
  $appKey = "dd-fennec-app-key"
}
$valuesFile =  (Get-Content "$workingFolder/values.json" | Out-String | ConvertFrom-Json)
$valuesFile.datadog.apiKey = $apiKey
$valuesFile.datadog.appKey = $appKey
$valuesFile | ConvertTo-Json -depth 100 | Out-File "$executeValuesFilepath"
$HelmChart.InstallHelmChart()


#kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode > ../../output/grafana-admin-secret




