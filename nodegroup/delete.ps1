#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'
if ($debug -Match 'NAME'){
    $nodeGroupName = 'generic-ng'
}
else {
    $nodeGroupName = '${NAME}'
}

$nodeProperties = @{
    nodeGroupName = "$nodeGroupName"
    workingFilePath = "$PSScriptRoot"
}
$NodeGroup = [GenericNodeGroup]::new($nodeProperties)
$NodeGroup.DeleteNodeGroup()