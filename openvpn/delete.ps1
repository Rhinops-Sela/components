#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/vpn-nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

$workingFolder= "$PSScriptRoot"
$name = "openvpn"
Write-Host "OpenVPN - PSScriptRoot: $workingFolder"
$HelmChart = [HelmChart]::new(@{
  name = "$name"
  chart = "stable/openvpn"
  namespace = [Namespace]::new("$name", $workingFolder)
  repoUrl = "http://storage.googleapis.com/kubernetes-charts"
  valuesFilepath = "$workingFolder/values.yaml"
  workingFolder = $workingFolder
  nodeGroup = [VPNNodeGroup]::new($workingFolder)
}, $true)

kubectl delete -f "$workingFolder/prerequisites/openvpn-pv-claim.yaml" -n vpn
$HelmChart.UninstallHelmChart()
