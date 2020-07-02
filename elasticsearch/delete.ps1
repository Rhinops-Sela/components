#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

$workingFolder= "$PSScriptRoot"
$ESValuesFilepath= "$workingFolder/es-values.json"
$KibanaValuesFilepath= "$workingFolder/kibana-values.json"
$ESExecuteValuesFilepath= "$workingFolder/es-values-execute.json"
$KibanaExecuteValuesFilepath= "$workingFolder/kibana-values-execute.json"

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
$esValuesFile =  (Get-Content $ESValuesFilepath | Out-String | ConvertFrom-Json)


$HelmChart = [HelmChart]::new(@{
  name = "elasticsearch"
  chart = "elastic/elasticsearch"
  repoUrl = "https://helm.elastic.co"
  namespace = [Namespace]::new("$namespace", $workingFolder)
  valuesFilepath = $ESExecuteValuesFilepath
  workingFolder = $workingFolder
  nodeGroup = $NodeGroup
}, $true)
if($HelmChart.debug){
  $source = "elasticsearch.fennec.io"
} else {
  $valuesFile.minimumMasterNodes = ${NUMBER_MASTERS}
  $valuesFile.replicas = ${NUMBER_SLAVES}
  $source = "${ES_DNS_RECORD}"
}
$esValuesFile | ConvertTo-Json -depth 100 | Out-File "$ESExecuteValuesFilepath"
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
$installKibana = 'true'
if(!$HelmChart.debug){
  $installKibana = '${INSTALL_KIBANA}'
}
if($installKibana -eq "true"){
  $HelmChart = [HelmChart]::new(@{
    name = "kibana"
    chart = "elastic/kibana"
    repoUrl = "https://helm.elastic.co"
    namespace = [Namespace]::new("$namespace", $workingFolder)
    valuesFilepath = $KibanaExecuteValuesFilepath
    workingFolder = $workingFolder
    nodeGroup = $NodeGroup
  }, $true)
  if($HelmChart.debug){
    $source = "kibana.fennec.io"
  } else {
    $source = "${KIBANA_DNS_RECORD}"
  }
  $kibanaValuesFile =  (Get-Content $KibanaValuesFilepath | Out-String | ConvertFrom-Json)
  $kibanaValuesFile.elasticsearchHosts = "http://elasticsearch-master.$namespace.svc.cluster.local:9200"
  $kibanaValuesFile | ConvertTo-Json -depth 100 | Out-File "$KibanaExecuteValuesFilepath"
  $HelmChart.UninstallHelmChart()

  $DNS = [CoreDNS]::new($workingFolder)
  $DNS.DeleteEntries(
                    @(
                      @{
                        Source = "$source"
                        Target = "kibana-kibana.$namespace.svc.cluster.local"
                      }
                    )
                  )
}
