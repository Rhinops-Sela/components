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
    [String]$tagsToAdd
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
    $this.Init($nodeProperties)
  }

  GenericNodeGroup([NodeProperties]$nodeProperties, [String]$templateFolder, [String]$templateName):base($nodeProperties.workingFilePath)
  {
    $this.templatePath = Join-Path $templateFolder $templateName
    $this.Init($nodeProperties)
  }

  Init([NodeProperties]$nodeProperties){
    $nodeProperties.clusterName = $this.clusterName
    $nodeProperties.region = $this.clusterRegion
    $nodeProperties.templatePath = $this.templatePath
    $this.nodeProperties = $nodeProperties
    $this.nodeProperties.tagsToAdd = "k8s.io/cluster-autoscaler/node-template/label/role=$($nodeProperties.nodeGroupName);k8s.io/cluster-autoscaler/node-template/taint/$($nodeProperties.nodeGroupName)=true:NoSchedule"
  }

  DeleteNodeGroup(){
    $this.CreateJSONFile()
    Write-Host "Deleting Nodegroup: $($this.nodeProperties.nodeGroupName)"
    $exitCode = $this.ExecuteCommand("eksctl", "delete nodegroup -f $($this.templatePath) --approve")
    if($exitCode -eq 0){
      Write-Host "NG Delted!"
    } else {
      Write-Error "Failed to delete NG"
    }
  }

  CreateNodeGroup(){
    Write-Host "before CreateJSONFile"
    $this.CreateJSONFile()
    Write-Host "Creating Nodegroup: $($this.nodeProperties.nodeGroupName)"
    $exitCode =  $this.ExecuteCommand("eksctl", "create nodegroup -f $($this.templatePath)")
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
    $nodegroupTemplate = $this.AddTags($nodegroupTemplate)
    $nodegroupTemplate | ConvertTo-Json -depth 100 | Out-File "$($this.templatePath)"
  }

  [psobject]AddMetaData($nodegroupTemplate){
      $OuterDelimiter = ';'
      $InnerDelimiter = '='
      $MetadataToAdd = "name=$($this.nodeProperties.clusterName);region=$($this.nodeProperties.region)"
      $metadata = $this.AddProperties($OuterDelimiter, $InnerDelimiter, $MetadataToAdd)
      $nodegroupTemplate | Add-Member  -MemberType NoteProperty -Name metadata -Value $metadata -Force
      return $nodegroupTemplate
  }

  [psobject]AddTaints($nodegroupTemplate){
    if(!$this.nodeProperties.taintsToAdd){
      return $nodegroupTemplate
    }
    $OuterDelimiter = ';'
    $InnerDelimiter = '='
    $taints = $this.AddProperties($OuterDelimiter, $InnerDelimiter, $this.nodeProperties.taintsToAdd)
    $nodegroupTemplate.nodeGroups | Add-Member  -MemberType NoteProperty -Name 'taints' -Value $taints -Force
    return $nodegroupTemplate
  }

  [psobject]AddTags($nodegroupTemplate){
    if(!$this.nodeProperties.taintsToAdd){
      return $nodegroupTemplate
    }
    $OuterDelimiter = ';'
    $InnerDelimiter = '='
    $tags = $this.AddProperties($OuterDelimiter, $InnerDelimiter, $this.nodeProperties.tagsToAdd)
    $nodegroupTemplate.nodeGroups | Add-Member  -MemberType NoteProperty -Name 'tags' -Value $tags -Force
    return $nodegroupTemplate
  }

  [psobject]AddARNsPolicies($nodegroupTemplate){
    if(!$this.nodeProperties.additionalARNs){
      return $nodegroupTemplate
    }
    $currentPolicies = $this.AddArrayItems($this.nodeProperties.additionalARNs, ';', $this.BasePolicies)
    $nodegroupTemplate.nodeGroups.iam | Add-Member  -MemberType NoteProperty -Name 'attachPolicyARNs' -Value $currentPolicies -Force
    return $nodegroupTemplate
  }

  [psobject]CreateInstancesDistribution($nodegroupTemplate){
    $InstanceDistribution =  New-Object PSObject
    $InstanceDistribution = $this.AddInstanceTypes($InstanceDistribution)
    if($this.nodeProperties.spotProperties.useSpot) {
      $InstanceDistribution | Add-Member -MemberType NoteProperty -Name 'onDemandBaseCapacity' -Value $this.nodeProperties.spotProperties.onDemandBaseCapacity -Force
      $InstanceDistribution | Add-Member -MemberType NoteProperty -Name 'onDemandPercentageAboveBaseCapacity' -Value $this.nodeProperties.spotProperties.onDemandPercentageAboveBaseCapacity -Force
      $InstanceDistribution | Add-Member -MemberType NoteProperty -Name 'spotAllocationStrategy' -Value $this.nodeProperties.spotProperties.spotAllocationStrategy -Force
    }
    $nodegroupTemplate.nodeGroups | Add-Member  -MemberType NoteProperty -Name 'instancesDistribution' -Value $InstanceDistribution -Force
    return $nodegroupTemplate
  }


  [psobject]AddSpotConfiguration($InstanceDistribution){
    $InstanceTypesArr = $this.StrToArray(',', $this.nodeProperties.instanceTypes)
    $InstanceDistribution | Add-Member -MemberType NoteProperty -Name 'instanceTypes' -Value $InstanceTypesArr -Force
    return $InstanceDistribution
  }

  [psobject]AddInstanceTypes($InstanceDistribution){
    $InstanceTypesArr = $this.StrToArray(',', $this.nodeProperties.instanceTypes)
    $InstanceDistribution | Add-Member -MemberType NoteProperty -Name 'instanceTypes' -Value $InstanceTypesArr -Force
    return $InstanceDistribution
  }

  [psobject]AddLabels($nodegroupTemplate){
    if(!$this.nodeProperties.userLabelsStr){
      return $nodegroupTemplate
    }
    $OuterDelimiter = ';'
    $InnerDelimiter = '='
    $labels = $this.AddProperties($OuterDelimiter, $InnerDelimiter, $this.nodeProperties.userLabelsStr)
    $nodegroupTemplate.nodeGroups | Add-Member  -MemberType NoteProperty -Name labels -Value $labels -Force
    return $nodegroupTemplate
  }
}







