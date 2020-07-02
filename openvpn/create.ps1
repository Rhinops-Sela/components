#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'

$workingFolder= "$PSScriptRoot"
$name = "openvpn"
Write-Host "OpenVPN - PSScriptRoot: $workingFolder"

$nodeProperties = @{
      nodeGroupName = "vpn"
      workingFilePath = "$workingFolder"
      userLabelsStr = 'role=vpn'
      instanceTypes = 't3.large,t2.large'
      taintsToAdd = 'vpn=true:NoSchedule'
    }

$NodeGroup = [GenericNodeGroup]::new($nodeProperties,"$workingFolder/templates","vpn-ng-template.json")


$HelmChart = [HelmChart]::new(@{
  name = "$name"
  chart = "stable/openvpn"
  namespace = [Namespace]::new("$name", $workingFolder)
  repoUrl = "http://storage.googleapis.com/kubernetes-charts"
  valuesFilepath = "$workingFolder/values.yaml"
  workingFolder = $workingFolder
  nodeGroup = $NodeGroup
})
if(!$HelmChart.upgrade){
  kubectl create -f "$workingFolder/prerequisites/openvpn-pv-claim.yaml" -n $name
}
$HelmChart.InstallHelmChart()
[String]$usersToCreate = "${USERS}"
if($HelmChart.debug){
  $usersToCreate = "fennec_1,fennec_2"
}
bash ./keygen/generate-client-key.sh $usersToCreate $name $name $HelmChart.outputFolder 2>&1 | Out-Null
