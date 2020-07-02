#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'

$debug='${NAMESPACE}'
if ($debug -Match 'NAMESPACE'){
    $userLabelsStr = 'label1=value1;label2=value2'
    $instanceTypes = 't3.small,t2.small'
    $taintsToAdd = 'taint1=true:NoSchedule;taint2=true:NoSchedule'
    $additionalARNs = 'arn:aws:iam::aws:policy/AmazonS3FullAccess;arn:aws:iam::aws:policy/AmazonWorkMailFullAccess'
    $nodeGroupName = 'generic-ng'
    $useSpot = 'true'
    $spotAllocationStrategy = 'lowest-price'
    $onDenmandInstances = 0
    $min = 0
    $max = 1
    $desired = 0
} else
{
    $userLabelsStr = '${LABELS}'
    $instanceTypes = '${INSTANCE_TYPES}'
    $additionalARNs = '${ADITONAL_ARNS}'
    $useSpot = '${USE_SPOT}'
    $onDenmandInstances = ${ON_DEMAND_INSTANCES}
    $spotAllocationStrategy = '${SPOT_ALLOCATION_STRATEGY}'
    $taintsToAdd = '${TAINTS}'
    $nodeGroupName = '${NAME}'
    $min = ${MIN}
    $max = ${MAX}
    $desired = ${DESIRED}
}

$nodeProperties = @{
    nodeGroupName = "$nodeGroupName"
    workingFilePath = "$workingFolder"
    userLabelsStr = $userLabelsStr
    instanceTypes = "$instanceTypes"
    taintsToAdd = "$taintsToAdd"
    additionalARNs = "$additionalARNs"
}

if($useSpot -eq 'true'){
  $nodeProperties.spotProperties = @{
    onDemandBaseCapacity = $onDenmandInstances
    onDemandPercentageAboveBaseCapacity = 0
    spotAllocationStrategy = $spotAllocationStrategy
    useSpot = $useSpot
  }
}


$ngFile =  (Get-Content "$PSScriptRoot/templates/nodegroup-template.json" | Out-String | ConvertFrom-Json)
$ngFile.nodeGroups[0].name = $nodeGroupName
$ngFile.nodeGroups[0].minSize = $min
$ngFile.nodeGroups[0].maxSize = $max
$ngFile.nodeGroups[0].desiredCapacity = $desired
$ngFile | ConvertTo-Json -depth 100 | Out-File "$PSScriptRoot/templates/nodegroup-template-execute.json"

$NodeGroup = [GenericNodeGroup]::new($nodeProperties,"$PSScriptRoot/templates","nodegroup-template-execute.json")
$NodeGroup.DeleteNodeGroup()

