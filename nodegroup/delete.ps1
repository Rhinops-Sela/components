#!/bin/pwsh
Set-Location -Path $PSScriptRoot
if ($debug -eq '${NAME}'){
    $userLabelsStr = 'label1=value1;label2=value2'
    $instanceTypes = 't3.small,t2.small'
    $taintsToAdd = 'taint1=true:NoSchedule;taint2=true:NoSchedule'
    $additionalARNs = 'arn:aws:iam::aws:policy/AmazonS3FullAccess;arn:aws:iam::aws:policy/AmazonWorkMailFullAccess'
    $filepostfix = '.ydebug'
    $useSpot = 'true'
    $spotAllocationStrategy = 'lowest-price'
    $onDenmandInstances = 0
    $clusterName = "fennec-cluster"
    $clusterRegion = "eu-west-1"
    $jsonFileName = 'nodegroup_template.json.debug'
}
else {
    aws configure set aws_access_key_id $Env:AWS_ACCESS_KEY_ID
    aws configure set aws_secret_access_key $Env:AWS_SECRET_ACCESS_KEY
    aws configure set region $Env:AWS_DEFAULT_REGION
    $userLabelsStr = '${LABELS}'
    $instanceTypes = '${INSTANCE_TYPE}'
    $additionalARNs = '${ADITONAL_ARNS}'
    $useSpot = '${SPOT}'
    $onDenmandInstances = ${ON_DEMAND_INSTANCES}
    $spotAllocationStrategy = ${SPOT_ALLOCATION_STRATEGY}
    $taintsToAdd = '${TAINTS}'
    $filepostfix = ''
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
    templatePath = "$PSScriptRoot/$jsonFileName"
    clusterName =  $clusterName
    region =  $clusterRegion
    spotProperties = $spotProperties
    userLabelsStr = $userLabelsStr
    instanceTypes = $instanceTypes
    additionalARNs = $additionalARNs
    taintsToAdd = $taintsToAdd
}
DeleteNodeGroup $nodeProperties
