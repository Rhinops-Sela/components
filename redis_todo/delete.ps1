#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

$workingFolder= "$PSScriptRoot"
$valuesFilepath= "$workingFolder/values.json"
$executeValuesFilepath= "$workingFolder/values-execute.json"
Write-Host "Redis - PSScriptRoot: $workingFolder"
$debug='${NAME}'
if ($debug -Match 'NAME'){
  $instanceTypes = 'm5.large,m5.xlarge'
  $namespace = "redis"
} else
{
  $instanceTypes = '${INSTANCE_TYPES}'
  $namespace = '${NAMESPACE}'
}

$nodeProperties = @{
      nodeGroupName = "redis"
      workingFilePath = "$workingFolder"
      userLabelsStr = 'role=redis'
      instanceTypes = "$instanceTypes"
      taintsToAdd = 'redis=true:NoSchedule'
    }



$NodeGroup = [GenericNodeGroup]::new($nodeProperties,"$workingFolder/templates","redis-ng-template.json")


$HelmChart = [HelmChart]::new(@{
  name = "redis"
  chart = "bitnami/redis"
  namespace = [Namespace]::new("$namespace", $workingFolder)
  repoUrl = "https://charts.bitnami.com/bitnami"
  valuesFilepath = $executeValuesFilepath
  workingFolder = $workingFolder
  nodeGroup = $NodeGroup
}, $true)
$valuesFile =  (Get-Content $valuesFilepath | Out-String | ConvertFrom-Json)
if($HelmChart.debug){
 $source = "reddis.fennec.io"
} else {
  $valuesFile.cluster.slaveCount = ${NUMBER_SLAVES}
  $valuesFile.master.extraFlags = "${EXTRA_FLAGS}".Split(",")
  $valuesFile.master.disableCommands = "${DISABLED_COMMANDS}".Split(",")
  $valuesFile.slave.disableCommands = "${DISABLED_COMMANDS}".Split(",")
  $source = "${DNS_RECORD}"
}
$valuesFile | ConvertTo-Json -depth 100 | Out-File "$executeValuesFilepath"
$HelmChart.UninstallHelmChart()

$DNS = [CoreDNS]::new($workingFolder)
$DNS.DeleteEntries(
                  @(
                    @{
                      Source = "$source"
                      Target = "redis.$namespace.svc.cluster.local"
                    }
                  )
                )
