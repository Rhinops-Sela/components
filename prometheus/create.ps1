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

Write-Host "Prometheus - PSScriptRoot: $workingFolder"
$HelmChart = [HelmChart]::new(@{
  name = "prometheus"
  chart = "stable/prometheus"
  namespace = [Namespace]::new("monitoring", $workingFolder)
  repoUrl = "https://kubernetes-charts.storage.googleapis.com"
  valuesFilepath = $executeValuesFilepath
  workingFolder = $workingFolder
  nodeGroup = [MonitoringNodeGroup]::new($workingFolder)
})
if($HelmChart.debug){
  $templateFilesPath += "debug/"
}
#Load JSON files
$alertManager = (Get-Content "$templateFilesPath/alert-manager.json" | Out-String | ConvertFrom-Json)
$alertmanagerYAML = $alertManager.alertmanagerFiles."alertmanager.yml"
$valuesFile =  (Get-Content $valuesFilepath | Out-String | ConvertFrom-Json)

if($HelmChart.debug){
  $alertmanagerYAML.route.receiver = "email-alert"
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
  $alertmanagerYAML.route.receiver = "${DEFAULT_RECEIVER}-alert"
  [System.Convert]::ToBoolean($addEmailReceiver)
  if($addEmailReceiver -And [System.Convert]::ToBoolean($addEmailReceiver)){
    $receivers += "$templateFilesPath/email-receiver.json"
    $routes += "$templateFilesPath/email-route.json"
  }
  if($addSlackReceiver -And [System.Convert]::ToBoolean($addSlackReceiver)){
    $receivers += "$templateFilesPath/slack-receiver.json"
    $routes += "$templateFilesPath/slack-route.json"

  }
  if($addWebhooksReceiver -And [System.Convert]::ToBoolean($addWebhooksReceiver)){
    $receivers += "$templateFilesPath/webhooks-receiver.json"
    $routes += "$templateFilesPath/webhooks-route.json"
  }
}

$alertmanagerYAML.receivers = $HelmChart.AddArrayItems($receivers,$alertmanagerYAML.receivers)
$alertmanagerYAML.route.routes = $HelmChart.AddArrayItems($routes,$alertmanagerYAML.route.routes)

$valuesFile | Add-Member -MemberType NoteProperty -Name "alertmanagerFiles" -Value $alertManager.alertmanagerFiles -Force
$valuesFile | ConvertTo-Json -depth 100 | Out-File "$executeValuesFilepath"
$HelmChart.InstallHelmChart()

$DNS = [CoreDNS]::new($workingFolder)
$DNS.AddEntries(
                  @(
                    @{
                      Source = "${SERVER_DNS_RECORD}"
                      Target = "prometheus.monitoring.svc.cluster.local"
                    },
                    @{
                      Source = "${ALERTMANAGER_RECORD}"
                      Target = "prometheus-alertmanager.monitoring.svc.cluster.local"
                    }
                  )
                )
#kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode > ../../output/grafana-admin-secret




