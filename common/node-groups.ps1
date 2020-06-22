. ../common/helper.ps1
class Spot {
    [int]$OnDemandBaseCapacity
    [int]$OnDemandPercentageAboveBaseCapacity
    [String]$SpotAllocationStrategy
    [boolean]$useSpot
 }

 class NodeGroup {
    [String]$nodeGroupName
    [String]$templatePath
    [String]$clusterName
    [String]$region
    [Spot]$spotProperties
    [String]$userLabelsStr
    [String]$instanceTypes
    [String]$additionalARNs
    [String]$taintsToAdd
 }

 $BasePolicies = @(
          "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
          "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
          "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  )

 function CreateNodeGroup([NodeGroup]$nodeProperties){
  Write-Host "Creating Nodegroup: $nodeGroupName"
  $nodegroupTemplate = (Get-Content $nodeProperties.templatePath | Out-String | ConvertFrom-Json)
  $nodegroupTemplate = AddMetaData $nodeProperties.clusterName $nodeProperties.region $nodegroupTemplate
  $nodegroupTemplate = AddLabels $nodeProperties.userLabelsStr $nodegroupTemplate
  $nodegroupTemplate = CreateInstancesDistribution $nodeProperties.instanceTypes $spotProperties $nodegroupTemplate
  $nodegroupTemplate = AddARNsPolicies $nodeProperties.additionalARNs $nodegroupTemplate
  $nodegroupTemplate = AddTaints $nodeProperties.taintsToAdd $nodegroupTemplate
  CreateJSONFile $nodegroupTemplate
  eksctl create nodegroup -f "nodegroup_execute.json"
  $result=ValidateNodegroup $nodeProperties.clusterName $nodeProperties.nodeGroupName
  return $result
 }

 function CreateJSONFile($nodegroupTemplate){
  $nodegroupTemplate | ConvertTo-Json -depth 100 | Out-File "nodegroup_execute.json"
  
 }

 function AddMetaData([String]$ClusterName, [String]$Region){
    $OuterDelimiter = ';'
    $InnerDelimiter = '='
    $MetadataToAdd = "name=$ClusterName;region=$Region"
    $metadata = AddProperties $OuterDelimiter $InnerDelimiter $MetadataToAdd
    $nodegroupTemplate | Add-Member  -MemberType NoteProperty -Name metadata -Value $metadata
    return $nodegroupTemplate
 }


function AddTaints([String]$TaintsToAdd, $nodegroupTemplate){
  if(!$TaintsToAdd){
    return $nodegroupTemplate
  }
  $Taints =  New-Object PSObject
  $OuterDelimiter = ';'
  $InnerDelimiter = '='
  $taints = AddProperties $OuterDelimiter $InnerDelimiter $TaintsToAdd
  $nodegroupTemplate.nodeGroups | Add-Member  -MemberType NoteProperty -Name 'taints' -Value $taints
  return $nodegroupTemplate
}

function AddARNsPolicies([string]$Policies,  $nodegroupTemplate){
  if(!$Policies){
    return $nodegroupTemplate
  }
  $currentPolicies = AddArrayItems $Policies ';' $BasePolicies
  $nodegroupTemplate.nodeGroups.iam | Add-Member  -MemberType NoteProperty -Name 'attachPolicyARNs' -Value $currentPolicies
  return $nodegroupTemplate
}

function CreateInstancesDistribution([String]$InstanceTypes, [Spot]$SpotPropertoies,  $nodegroupTemplate){
  $InstanceDistribution =  New-Object PSObject
  $InstanceDistribution = AddInstanceTypes $InstanceTypes $InstanceDistribution
  if($SpotPropertoies.useSpot) {
    $InstanceDistribution | Add-Member -MemberType NoteProperty -Name 'onDemandBaseCapacity' -Value $SpotPropertoies.onDemandBaseCapacity
    $InstanceDistribution | Add-Member -MemberType NoteProperty -Name 'onDemandPercentageAboveBaseCapacity' -Value $SpotPropertoies.onDemandPercentageAboveBaseCapacity
    $InstanceDistribution | Add-Member -MemberType NoteProperty -Name 'spotAllocationStrategy' -Value $SpotPropertoies.spotAllocationStrategy
  }
  $nodegroupTemplate.nodeGroups | Add-Member  -MemberType NoteProperty -Name 'instancesDistribution' -Value $InstanceDistribution
  return $nodegroupTemplate
}


function AddSpotConfiguration([String]$InstanceTypes, $InstanceDistribution){
  $InstanceTypesArr = StrToArray ',' $InstanceTypes
  $InstanceDistribution | Add-Member -MemberType NoteProperty -Name 'instanceTypes' -Value $InstanceTypesArr
  return $InstanceDistribution
}

function AddInstanceTypes([String]$InstanceTypes, $InstanceDistribution){
  $InstanceTypesArr = StrToArray ',' $InstanceTypes
  $InstanceDistribution | Add-Member -MemberType NoteProperty -Name 'instanceTypes' -Value $InstanceTypesArr
  return $InstanceDistribution
}

function AddLabels([String]$LabelsToAdd, $nodegroupTemplate){
  if(!$LabelsToAdd){
    return $nodegroupTemplate
  }
  $OuterDelimiter = ';'
  $InnerDelimiter = '='
  $labels = AddProperties $OuterDelimiter $InnerDelimiter $LabelsToAdd
  $nodegroupTemplate.nodeGroups | Add-Member  -MemberType NoteProperty -Name labels -Value $labels
  return $nodegroupTemplate
}