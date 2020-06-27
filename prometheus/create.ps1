#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/monitoring-nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

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
 $alertManager = (Get-Content "$templateFilesPath/alert-manager.json" | Out-String | ConvertFrom-Json)
 $emailReceiver = (Get-Content "$templateFilesPath/email-receiver.json" | Out-String | ConvertFrom-Json)
 $emailRoute = (Get-Content "$templateFilesPath/email-route.json" | Out-String | ConvertFrom-Json)
 $slackReceiver = (Get-Content "$templateFilesPath/slack-receiver.json" | Out-String | ConvertFrom-Json)
 $slackRoute = (Get-Content "$templateFilesPath/slack-route.json" | Out-String | ConvertFrom-Json)
 $webhooksReceiver = (Get-Content "$templateFilesPath/webhooks-receiver.json" | Out-String | ConvertFrom-Json)
 $webhooksRoute = (Get-Content "$templateFilesPath/webhooks-route.json" | Out-String | ConvertFrom-Json)

$valuesFile =  (Get-Content $valuesFilepath | Out-String | ConvertFrom-Json)


if($HelmChart.debug){
  $alertManager.alertmanagerFiles."alertmanager.yml".route.receiver = "slack-alert"
  $alertManager.alertmanagerFiles."alertmanager.yml".receivers += $emailReceiver
  $alertManager.alertmanagerFiles."alertmanager.yml".route.routes += $emailRoute
  $alertManager.alertmanagerFiles."alertmanager.yml".receivers += $slackReceiver
  $alertManager.alertmanagerFiles."alertmanager.yml".route.routes += $slackRoute
  $alertManager.alertmanagerFiles."alertmanager.yml".receivers += $webhooksReceiver
  $alertManager.alertmanagerFiles."alertmanager.yml".route.routes += $webhooksRoute
 
} else {
  $addEmailReceiver = "${EMAIL_NOTIFER}"
  $addSlackReceiver = "${SLACK_NOTIFER}"
  $addWebhooksReceiver = "${WEBHOOK_NOTIFER}"
  if($addEmailReceiver){
    $alertManager.alertmanagerFiles."alertmanager.yml".receivers += $emailReceiver
    $alertManager.alertmanagerFiles."alertmanager.yml".route.routes += $emailRoute
    $alertManager.alertmanagerFiles."alertmanager.yml".route.receiver = "email-alert"
  }
  if($addSlackReceiver){
    $alertManager.alertmanagerFiles."alertmanager.yml".receivers += $slackReceiver
    $alertManager.alertmanagerFiles."alertmanager.yml".route.routes += $slackRoute
    $alertManager.alertmanagerFiles."alertmanager.yml".route.receiver = "slack-alert"
  }
  if($addWebhooksReceiver){
    $alertManager.alertmanagerFiles."alertmanager.yml".receivers += $webhooksReceiver
    $alertManager.alertmanagerFiles."alertmanager.yml".route.routes += $webhooksRoute
    $alertManager.alertmanagerFiles."alertmanager.yml".route.receiver = "webhooks-alert"
  }
}
$valuesFile | Add-Member -MemberType NoteProperty -Name "alertmanagerFiles" -Value $alertManager.alertmanagerFiles
$valuesFile | ConvertTo-Json -depth 100 | Out-File "$executeValuesFilepath"
$HelmChart.InstallHelmChart()







#kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode > ../../output/grafana-admin-secret




