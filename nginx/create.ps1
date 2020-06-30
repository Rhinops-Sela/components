#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/monitoring-nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

$workingFolder= "$PSScriptRoot"
$valuesFilepath= "$workingFolder/values.json"
$executeValuesFilepath= "$workingFolder/values-execute.json"

Write-Host "Nginx - PSScriptRoot: $workingFolder"
$HelmChart = [HelmChart]::new(@{
  name = "ingress-nginx"
  chart = "ingress-nginx/ingress-nginx"
  namespace = [Namespace]::new("nginx", $workingFolder)
  repoUrl = "https://kubernetes.github.io/ingress-nginx"
  valuesFilepath = "$executeValuesFilepath"
  workingFolder = $workingFolder
})
$private = "true"
if("${DNS_RECORD}" -eq "Public") {
  $private = "flase"
}

$valuesFile =  (Get-Content $valuesFilepath | Out-String | ConvertFrom-Json)
$valuesFile.controller.service.annotations."service.beta.kubernetes.io/aws-load-balancer-internal" = "$private"
$valuesFile | ConvertTo-Json -depth 100 | Out-File "$executeValuesFilepath"

$HelmChart.InstallHelmChart()



