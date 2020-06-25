#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/monitoring-nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Set-Location -Path $PSScriptRoot
$nodeProperties = @{
    nodeGroupName = "monitoring"
    workingFilePath = "$PSScriptRoot"
}
$Namespace = [Namespace]::new("monitoring", "$($PSScriptRoot)/.kube")
$Namespace.DeleteNamespace()
$MonitoringNodeGroup = [MonitoringNodeGroup]::new($nodeProperties)
$MonitoringNodeGroup.DeleteNodeGroup()