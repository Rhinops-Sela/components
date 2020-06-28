class Parent {
  $clusterName
  $clusterRegion
  $templatePath
  $debug=$false
  $kubeConfigFile
  Parent([String]$workingFilePath){
    if ($Env:CLUSTER_NAME){
        aws configure set aws_access_key_id $Env:AWS_ACCESS_KEY_ID
        aws configure set aws_secret_access_key $Env:AWS_SECRET_ACCESS_KEY
        aws configure set region $Env:AWS_DEFAULT_REGION
        $this.clusterName = $Env:CLUSTER_NAME
        $this.clusterRegion = $Env:CLUSTER_REGION
    }
    else {
        $this.clusterName = "fennec"
        $this.clusterRegion = "eu-west-2"
        $this.debug = $true
    }
    Write-Host "Parent - PSScriptRoot: $PSScriptRoot"
    $this.kubeConfigFile = "$workingFilePath/.kube"
    aws eks update-kubeconfig --name $this.clusterName --region $this.clusterRegion --kubeconfig $this.kubeConfigFile
    $env:KUBECONFIG = $this.kubeConfigFile
  }

  [psobject]AddArrayItems([String]$ArrayString, $Delimiter, $BaseArray){
    $Array = $this.StrToArray($Delimiter, $ArrayString)
    $BaseArray += $Array
    return $BaseArray
  }

  [psobject]AddArrayItems([String[]] $JSONPaths, $BaseArray){
    foreach ($JSONPath in $JSONPaths){
      $Object = (Get-Content "$JSONPath" | Out-String | ConvertFrom-Json)
      $BaseArray += $Object
    }
    return $BaseArray
  }

  [psobject]AddProperties([String] $OuterDelimiter,[String] $InnerDelimiter,[String]$ItemsToAdd){
    return $this.AddProperties([String] $OuterDelimiter,[String] $InnerDelimiter,[String]$ItemsToAdd, $null)
  }

  [psobject]AddProperties([String] $OuterDelimiter,[String] $InnerDelimiter,[String]$ItemsToAdd, $BaseObject){
    if(!$BaseObject){
      $BaseObject = New-Object PSObject
    }
    $Properties = $this.StrToArray($OuterDelimiter, $ItemsToAdd)
    foreach ($Property in $Properties) {
    $Split = $this.StrToArray($InnerDelimiter, $Property)
    $BaseObject | Add-Member -MemberType NoteProperty -Name $Split[0] -Value $Split[1]
  }
  return $BaseObject
  }

  [psobject]StrToArray([String] $Delimiter, [String]$StringToParse) {
    return $StringToParse.split($Delimiter)
  }
}