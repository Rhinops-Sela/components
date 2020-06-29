#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'
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
}
$nodeProperties = @{
    nodeGroupName = "$nodeGroupName"
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

$NodeGroup = [GenericNodeGroup]::new($nodeProperties,"nodegroup-template.json")
$NodeGroup.CreateNodeGroup()

