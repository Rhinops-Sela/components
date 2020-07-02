#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'

$debug='${NAME}'
if ($debug -Match 'NAMESPACE'){
    $nodeGroupName = 'fennec-ng'
    $userLabelsStr = 'label1=value1;label2=value2'
    $instanceTypes = 't3.small,t2.small'
    $taintsToAdd = 'taint1=true:NoSchedule;taint2=true:NoSchedule'
    $additionalARNs = 'arn:aws:iam::aws:policy/AmazonS3FullAccess;arn:aws:iam::aws:policy/AmazonWorkMailFullAccess'
    $useSpot = 'true'
    $spotAllocationStrategy = 'lowest-price'
    $onDenmandInstances = 0
} else
{
    $userLabelsStr = '${LABELS}'
    $instanceTypes = '${INSTANCE_TYPES}'
    $taintsToAdd = '${TAINTS}'
    $additionalARNs = '${ADITONAL_ARNS}'
    $useSpot = '${USE_SPOT}'
    $spotAllocationStrategy = '${SPOT_ALLOCATION_STRATEGY}'
    $onDenmandInstances = ${ON_DEMAND_INSTANCES}
    $nodeGroupName = '${NAME}'
    $min = '${MIN}'
    $max = '${MAX}'
    $desired = '${DESIRED}'
}

$nodeProperties = @{
    nodeGroupName = $nodeGroupName
    workingFilePath = "$workingFolder"
    userLabelsStr = $userLabelsStr
    instanceTypes = "$instanceTypes"
    taintsToAdd = $taintsToAdd
}

if($useSpot -eq 'true'){
  $nodeProperties.spotProperties = @{
    onDemandBaseCapacity = $onDenmandInstances
    onDemandPercentageAboveBaseCapacity = 0
    spotAllocationStrategy = $spotAllocationStrategy
    useSpot = $useSpot
  }
}
$NodeGroup = [GenericNodeGroup]::new($nodeProperties,"$workingFolder/templates","nodegroup-template.json")


$debug='${NAME}'
Write-Host "PSScriptRoot: $PSScriptRoot"
if ($debug -Match 'NAME'){
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
}
else {
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
    workingFilePath = "$PSScriptRoot"
    spotProperties = @{
        onDemandBaseCapacity = $onDenmandInstances
        onDemandPercentageAboveBaseCapacity = 0
        spotAllocationStrategy = $spotAllocationStrategy
        useSpot = $useSpot
    }
    userLabelsStr = $userLabelsStr
    instanceTypes = $instanceTypes
    additionalARNs = $additionalARNs
    taintsToAdd = $taintsToAdd
}

$ngFile =  (Get-Content "$PSScriptRoot/nodegroup-template.json" | Out-String | ConvertFrom-Json)
$ngFile.nodeGroups.minSize = $min
$ngFile.nodeGroups.maxSize = $max
$ngFile.nodeGroups.desiredCapacity = $desired
$ngFile | ConvertTo-Json -depth 100 | Out-File "$PSScriptRoot/nodegroup-template-execute.json"

$NodeGroup = [GenericNodeGroup]::new($nodeProperties,"$PSScriptRoot","nodegroup-template-execute.json")
$NodeGroup.DeleteNodeGroup()

