#!/bin/pwsh
Using module '$PSScriptRoot/../common/nodegroups/nodegroup.psm1'
$debug='${NAME}'
Set-Location -Path $PSScriptRoot

if ($debug -Match 'NAME'){
    $userLabelsStr = 'label1=value1;label2=value2'
    $instanceTypes = 't3.small,t2.small'
    $taintsToAdd = 'taint1=true:NoSchedule;taint2=true:NoSchedule'
    $additionalARNs = 'arn:aws:iam::aws:policy/AmazonS3FullAccess;arn:aws:iam::aws:policy/AmazonWorkMailFullAccess'
    $nodeGroupName = 'ilia-ng1'
    $useSpot = 'true'
    $spotAllocationStrategy = 'lowest-price'
    $onDenmandInstances = 0
    $clusterName = "fennec"
    $clusterRegion = "eu-west-2"
    $jsonFileName = 'nodegroup_template.json.debug'
}
else {
    aws configure set aws_access_key_id $Env:AWS_ACCESS_KEY_ID
    aws configure set aws_secret_access_key $Env:AWS_SECRET_ACCESS_KEY
    aws configure set region $Env:AWS_DEFAULT_REGION
    $userLabelsStr = '${LABELS}'
    $instanceTypes = '${INSTANCE_TYPES}'
    $additionalARNs = '${ADITONAL_ARNS}'
    $useSpot = '${USE_SPOT}'
    $onDenmandInstances = ${ON_DEMAND_INSTANCES}
    $spotAllocationStrategy = '${SPOT_ALLOCATION_STRATEGY}'
    $taintsToAdd = '${TAINTS}'
    $nodeGroupName = '${NAME}'
    $clusterName = $Env:CLUSTER_NAME
    $clusterRegion = $Env:CLUSTER_REGION
    $jsonFileName = 'nodegroup_template.json'
}


$spotProperties = @{
    onDemandBaseCapacity = $onDenmandInstances
    onDemandPercentageAboveBaseCapacity = 0
    spotAllocationStrategy = $spotAllocationStrategy
    useSpot = $useSpot
}
$nodeProperties = @{
    nodeGroupName = "$nodeGroupName"
    templatePath = "$PSScriptRoot/$jsonFileName"
    workingFilePath = "$PSScriptRoot"
    clusterName =  $clusterName
    region =  $clusterRegion
    spotProperties = $spotProperties
    userLabelsStr = $userLabelsStr
    instanceTypes = $instanceTypes
    additionalARNs = $additionalARNs
    taintsToAdd = $taintsToAdd
}

$NodeGroup = [GenericNodeGroup]::new($nodeProperties)
$NodeGroup.CreateNodeGroup()

