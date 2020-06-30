Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'
class VPNNodeGroup : GenericNodeGroup {
  VPNNodeGroup([String]$WorkingFilePath):base(@{
      nodeGroupName = "vpn"
      workingFilePath = "$WorkingFilePath"
      userLabelsStr = 'role=vpn'
      instanceTypes = 't3.large,t2.large'
      taintsToAdd = 'vpn=true:NoSchedule'
    }, "vpn-ng-template.json"){
  }
}