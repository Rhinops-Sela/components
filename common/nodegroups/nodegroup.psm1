Using module '$PSScriptRoot/../../common/parent.psm1'
class Spot {
    [int]$OnDemandBaseCapacity
    [int]$OnDemandPercentageAboveBaseCapacity
    [String]$SpotAllocationStrategy
    [boolean]$useSpot
 }

class NodeProperties {
    [String]$nodeGroupName
    [String]$templatePath
    [String]$workingFilePath
    [String]$clusterName
    [String]$region
    [Spot]$spotProperties
    [String]$userLabelsStr
    [String]$instanceTypes
    [String]$additionalARNs
    [String]$taintsToAdd
}
class GenericNodeGroup: Parent {
  $BasePolicies = @(
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  )
  [NodeProperties]$nodeProperties
  GenericNodeGroup([NodeProperties]$nodeProperties, [String]$templateName):base($nodeProperties.workingFilePath)
  {
    if($this.debug){
      $this.templatePath = "$PSScriptRoot/templates/debug/$templateName"
    } else {
      $this.templatePath = "$PSScriptRoot/templates/$templateName"
    }
    $nodeProperties.clusterName = $this.clusterName
    $nodeProperties.region = $this.clusterRegion
    $nodeProperties.templatePath = $this.templatePath
    $this.nodeProperties = $nodeProperties
  }

  DeleteNodeGroup(){
    $this.CreateJSONFile()
    Write-Host "Deleting Nodegroup: $($this.nodeProperties.nodeGroupName)"
    $exitCode = $this.ExecuteCommand("eksctl", "delete nodegroup -f $($this.nodeProperties.workingFilePath)/nodegroup-execute.json --approve")
    if($exitCode -eq 0){
      Write-Host "NG Delted!"
    } else {
      Write-Error "Failed to delete NG"
    }
  }

  CreateNodeGroup(){
    $this.CreateJSONFile()
    Write-Host "Creating Nodegroup: $($this.nodeProperties.nodeGroupName)"
    $exitCode =  $this.ExecuteCommand("eksctl", "create nodegroup -f $($this.nodeProperties.workingFilePath)/nodegroup-execute.json")
    if($exitCode -eq 0){
        Write-Host "NG Created!"
    } else {
      Write-Error "Failed to create NG"
    }
  }

  CreateJSONFile(){
    $nodegroupTemplate = (Get-Content $this.nodeProperties.templatePath | Out-String | ConvertFrom-Json)
    $nodegroupTemplate = $this.AddMetaData($nodegroupTemplate)
    $nodegroupTemplate = $this.AddLabels($nodegroupTemplate)
    $nodegroupTemplate = $this.CreateInstancesDistribution($nodegroupTemplate)
    $nodegroupTemplate = $this.AddARNsPolicies($nodegroupTemplate)
    $nodegroupTemplate = $this.AddTaints($nodegroupTemplate)
    $nodegroupTemplate | ConvertTo-Json -depth 100 | Out-File "$($this.nodeProperties.workingFilePath)/nodegroup-execute.json"
  }

  [psobject]AddMetaData($nodegroupTemplate){
      $OuterDelimiter = ';'
      $InnerDelimiter = '='
      $MetadataToAdd = "name=$($this.nodeProperties.clusterName);region=$($this.nodeProperties.region)"
      $metadata = $this.AddProperties($OuterDelimiter, $InnerDelimiter, $MetadataToAdd)
      $nodegroupTemplate | Add-Member  -MemberType NoteProperty -Name metadata -Value $metadata
      return $nodegroupTemplate
  }

 #$taintsToAdd = 'taint1=true:NoSchedule;taint2=true:NoSchedule'
  [psobject]AddTaints($nodegroupTemplate){
    if(!$this.nodeProperties.taintsToAdd){
      return $nodegroupTemplate
    }
    $OuterDelimiter = ';'
    $InnerDelimiter = '='
    $taints = $this.AddProperties($OuterDelimiter, $InnerDelimiter, $this.nodeProperties.taintsToAdd)
    $nodegroupTemplate.nodeGroups | Add-Member  -MemberType NoteProperty -Name 'taints' -Value $taints
    return $nodegroupTemplate
  }

  [psobject]AddARNsPolicies($nodegroupTemplate){
    if(!$this.nodeProperties.additionalARNs){
      return $nodegroupTemplate
    }
    $currentPolicies = $this.AddArrayItems($this.nodeProperties.additionalARNs, ';', $this.BasePolicies)
    $nodegroupTemplate.nodeGroups.iam | Add-Member  -MemberType NoteProperty -Name 'attachPolicyARNs' -Value $currentPolicies
    return $nodegroupTemplate
  }

  [psobject]CreateInstancesDistribution($nodegroupTemplate){
    $InstanceDistribution =  New-Object PSObject
    $InstanceDistribution = $this.AddInstanceTypes($InstanceDistribution)
    if($this.nodeProperties.spotProperties.useSpot) {
      $InstanceDistribution | Add-Member -MemberType NoteProperty -Name 'onDemandBaseCapacity' -Value $this.nodeProperties.spotProperties.onDemandBaseCapacity
      $InstanceDistribution | Add-Member -MemberType NoteProperty -Name 'onDemandPercentageAboveBaseCapacity' -Value $this.nodeProperties.spotProperties.onDemandPercentageAboveBaseCapacity
      $InstanceDistribution | Add-Member -MemberType NoteProperty -Name 'spotAllocationStrategy' -Value $this.nodeProperties.spotProperties.spotAllocationStrategy
    }
    $nodegroupTemplate.nodeGroups | Add-Member  -MemberType NoteProperty -Name 'instancesDistribution' -Value $InstanceDistribution
    return $nodegroupTemplate
  }


  [psobject]AddSpotConfiguration($InstanceDistribution){
    $InstanceTypesArr = $this.StrToArray(',', $this.nodeProperties.instanceTypes)
    $InstanceDistribution | Add-Member -MemberType NoteProperty -Name 'instanceTypes' -Value $InstanceTypesArr
    return $InstanceDistribution
  }

  [psobject]AddInstanceTypes($InstanceDistribution){
    $InstanceTypesArr = $this.StrToArray(',', $this.nodeProperties.instanceTypes)
    $InstanceDistribution | Add-Member -MemberType NoteProperty -Name 'instanceTypes' -Value $InstanceTypesArr
    return $InstanceDistribution
  }

  [psobject]AddLabels($nodegroupTemplate){
    if(!$this.nodeProperties.userLabelsStr){
      return $nodegroupTemplate
    }
    $OuterDelimiter = ';'
    $InnerDelimiter = '='
    $labels = $this.AddProperties($OuterDelimiter, $InnerDelimiter, $this.nodeProperties.userLabelsStr)
    $nodegroupTemplate.nodeGroups | Add-Member  -MemberType NoteProperty -Name labels -Value $labels
    return $nodegroupTemplate
  }
}







