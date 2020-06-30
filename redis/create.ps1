#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'

$workingFolder= "$PSScriptRoot"
$valuesFilepath= "$workingFolder/values.json"
$executeDeploymentFilepath= "$workingFolder/deploymnet-execute.json"
$executeValuesFilepath= "$workingFolder/values-execute.json"
Write-Host "Redis - PSScriptRoot: $workingFolder"
$debug='${NAME}'
if ($debug -Match 'NAME'){
  $instanceTypes = 'c4.large,c4.xlarge'
  $useSpot = 'true'
  $namespace = "redis"
} else
{
  $instanceTypes = '${INSTANCE_TYPES}'
  $useSpot = '${USE_SPOT}'
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
})
$valuesFile =  (Get-Content $valuesFilepath | Out-String | ConvertFrom-Json)
if($HelmChart.debug){
 $source = "reddis.fennec.io"
} else {
  $valuesFile.cluster.slaveCount = ${NUMBER_SLAVES}
  $valuesFile.master.extraFlags = "${EXTRA_FLAGS}".Split(",")
  $valuesFile.master.disableCommands = "${DISABLED_COMMANDS}".Split(",")
  $valuesFile.slave.disableCommands = "${DISABLED_COMMANDS}".Split(",")
}
$valuesFile | ConvertTo-Json -depth 100 | Out-File "$executeValuesFilepath"
$HelmChart.InstallHelmChart()

$source = "${DNS_RECORD}"


$DNS = [CoreDNS]::new($workingFolder)
$DNS.AddEntries(
                  @(
                    @{
                      Source = "$source"
                      Target = "redis.$namespace.svc.cluster.local"
                    }
                  )
                )
$ui="$workingFolder/ui"
$deplouymentFile =  (Get-Content "$ui/deployment.json" | Out-String | ConvertFrom-Json)
$deplouymentFile.spec.template.spec.containers.env.value = "redis.$namespace.svc.cluster.local"
$deplouymentFile | ConvertTo-Json -depth 100 | Out-File "$executeDeploymentFilepath"
kubectl apply -f "$ui/deployment.yaml" -n $namespace
kubectl apply -f "$ui/service.yaml" -n $namespace
