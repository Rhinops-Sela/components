#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/monitoring-nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

$receivers = @()
$routes = @()
$workingFolder= "$PSScriptRoot"
$valuesFilepath= "$workingFolder/values.json"
$executeValuesFilepath= "$workingFolder/values-execute.json"
$templateFilesPath= "$workingFolder/templates/"

Write-Host "Grafana - PSScriptRoot: $workingFolder"
$HelmChart = [HelmChart]::new(@{
  name = "prometheus"
  chart = "stable/prometheus"
  namespace = [Namespace]::new("monitoring", $workingFolder)
  repoUrl = "https://kubernetes-charts.storage.googleapis.com"
  valuesFilepath = $executeValuesFilepath
  workingFolder = $workingFolder
  nodeGroup = [MonitoringNodeGroup]::new($workingFolder)
  DNS = [CoreDNS]::new("prometheus.monitoring.svc.cluster.local",$workingFolder)
})
if($HelmChart.debug){
  $templateFilesPath += "debug/"
}
#Load JSON files
$alertmanagerYAML = $alertManager.alertmanagerFiles."alertmanager.yml"
$alertManager = (Get-Content "$templateFilesPath/alert-manager.json" | Out-String | ConvertFrom-Json)
$valuesFile =  (Get-Content $valuesFilepath | Out-String | ConvertFrom-Json)

if($HelmChart.debug){
  $alertmanagerYAML.route.receiver = "email-receiver"
  $receivers = @(
    "$templateFilesPath/email-receiver.json",
    "$templateFilesPath/slack-receiver.json",
    "$templateFilesPath/webhooks-receiver.json"
  )
  $routes = @(
    "$templateFilesPath/email-route.json",
    "$templateFilesPath/slack-route.json",
    "$templateFilesPath/webhooks-route.json"
  )
} else {
  $addEmailReceiver = "${EMAIL_NOTIFER}"
  $addSlackReceiver = "${SLACK_NOTIFER}"
  $addWebhooksReceiver = "${WEBHOOK_NOTIFER}"
  $alertmanagerYAML.route.receiver = "${DEFAULT_RECEIVER}"

  if($addEmailReceiver){
    $receivers += "$templateFilesPath/email-receiver.json"
    $routes += "$templateFilesPath/email-route.json"
  }
  if($addSlackReceiver){
    $receivers += "$templateFilesPath/slack-receiver.json"
    $routes += "$templateFilesPath/slack-route.json"

  }
  if($addWebhooksReceiver){
    $receivers += "$templateFilesPath/webhooks-receiver.json"
    $routes += "$templateFilesPath/webhooks-route.json"
  }
}

$alertmanagerYAML.receivers = $HelmChart.AddArrayItems($receivers,$alertmanagerYAML.receivers)
$alertmanagerYAML.route.routes = $HelmChart.AddArrayItems($routes,$alertmanagerYAML.route.routes)

$valuesFile | Add-Member -MemberType NoteProperty -Name "alertmanagerFiles" -Value $alertManager.alertmanagerFiles
$valuesFile | ConvertTo-Json -depth 100 | Out-File "$executeValuesFilepath"
$HelmChart.InstallHelmChart()







#kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode > ../../output/grafana-admin-secret




