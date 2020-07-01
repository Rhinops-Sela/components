#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

$workingFolder= "$PSScriptRoot"
$valuesFilepath= "$workingFolder/helm/elasticsearch/values.json"
$executeValuesFilepath= "$workingFolder/values-execute.json"
Write-Host "ElasticSearch - PSScriptRoot: $workingFolder"
$debug='${NAMESPACE}'
if ($debug -Match 'NAMESPACE'){
  $instanceTypes = "m5.xlarge,m5.2xlarge"
  $useSpot = 'true'
  $namespace = "elk"
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
      nodeGroupName = "elk"
      workingFilePath = "$workingFolder"
      userLabelsStr = 'role=elk'
      instanceTypes = "$instanceTypes"
      taintsToAdd = 'elk=true:NoSchedule'
    }

if($useSpot -eq 'true'){
$nodeProperties.spotProperties = @{
      onDemandBaseCapacity = $onDenmandInstances
      onDemandPercentageAboveBaseCapacity = 0
      spotAllocationStrategy = $spotAllocationStrategy
      useSpot = $useSpot
    }
}
$NodeGroup = [GenericNodeGroup]::new($nodeProperties,"$workingFolder/templates","es-ng-template.json")
$valuesFile =  (Get-Content $valuesFilepath | Out-String | ConvertFrom-Json)

$HelmChart = [HelmChart]::new(@{
  name = "elasticsearch"
  chart = "helm/elasticsearch"
  namespace = [Namespace]::new("$namespace", $workingFolder)
  valuesFilepath = $executeValuesFilepath
  workingFolder = $workingFolder
  nodeGroup = $NodeGroup
})
$valuesFile =  (Get-Content $valuesFilepath | Out-String | ConvertFrom-Json)
if($HelmChart.debug){
  $source = "elasticsearch.fennec.io"
} else {
  $valuesFile.minimumMasterNodes = ${NUMBER_MASTERS}
  $valuesFile.replicas = ${NUMBER_SLAVES}
  $source = "${DNS_RECORD}"
}
$valuesFile | ConvertTo-Json -depth 100 | Out-File "$executeValuesFilepath"
$HelmChart.UninstallHelmChart()

$DNS = [CoreDNS]::new($workingFolder)
$DNS.DeleteEntries(
                  @(
                    @{
                      Source = "$source"
                      Target = "elasticsearch-master.$namespace.svc.cluster.local"
                    }
                  )
                )