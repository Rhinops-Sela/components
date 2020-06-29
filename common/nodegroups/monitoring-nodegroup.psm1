Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'
class MonitoringNodeGroup : GenericNodeGroup {
  MonitoringNodeGroup([String]$WorkingFilePath):base(@{
      nodeGroupName = "monitoring"
      workingFilePath = "$WorkingFilePath"
      userLabelsStr = 'role=monitoring'
      instanceTypes = 't3.large,t2.large'
      taintsToAdd = 'monitoring=true:NoSchedule'
    }, "monitoring-ng-template.json"){
  }
}