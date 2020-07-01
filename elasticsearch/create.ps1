#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

$workingFolder= "$PSScriptRoot"
$valuesFilepath= "$workingFolder/helm/elasticsearch/values.yaml"
$executeDeploymentFilepath= "$workingFolder/deploymnet-execute.json"
$executeValuesFilepath= "$workingFolder/values-execute.json"
Write-Host "Redis - PSScriptRoot: $workingFolder"
$debug='${NAME}'
if ($debug -Match 'NAME'){
  $instanceTypes = 'm5.large,m5.xlarge'
  $useSpot = 'true'
  $namespace = "redis"
  $spotAllocationStrategy = 'lowest-price'
  $onDenmandInstances = 0
} else
{
  $instanceTypes = '${INSTANCE_TYPES}'
  $useSpot = '${USE_SPOT}'
  $onDenmandInstances = ${ON_DEMAND_INSTANCES}
  $spotAllocationStrategy = 'lowest-price'
  $namespace = '${NAMESPACE}'
}

$nodeProperties = @{
      nodeGroupName = "redis"
      workingFilePath = "$workingFolder"
      userLabelsStr = 'role=redis'
      instanceTypes = "$instanceTypes"
      taintsToAdd = 'redis=true:NoSchedule'
    }

if($useSpot -eq 'true'){
$nodeProperties.spotProperties = @{
      onDemandBaseCapacity = $onDenmandInstances
      onDemandPercentageAboveBaseCapacity = 0
      spotAllocationStrategy = $spotAllocationStrategy
      useSpot = $useSpot
    }
}
$NodeGroup = [GenericNodeGroup]::new($nodeProperties,"$workingFolder/templates","redis-ng-template.json")
$valuesFile =  (Get-Content $valuesFilepath | Out-String | ConvertFrom-Json)
if($Namespace.debug){
 $source = "dynamodb-ui.fennec.io"
} else {
  $valuesFile.cluster.slaveCount = ${NUMBER_SLAVES}
  $valuesFile.master.extraFlags = "${EXTRA_FLAGS}".Split(",")
  $valuesFile.master.disableCommands = "${DISABLED_COMMANDS}".Split(",")
  $valuesFile.slave.disableCommands = "${DISABLED_COMMANDS}".Split(",")
  $source = "${DNS_RECORD}"
}



$HelmChart = [HelmChart]::new(@{
  name = "redis"
  chart = "helm/elasticsearc"
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
  $source = "${DNS_RECORD}"
}
$valuesFile | ConvertTo-Json -depth 100 | Out-File "$executeValuesFilepath"
$HelmChart.InstallHelmChart()




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
kubectl apply -f "$ui/deployment.json" -n $namespace
kubectl apply -f "$ui/service.yaml" -n $namespace
