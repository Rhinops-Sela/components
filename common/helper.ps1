function Retry-Command {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Position=1, Mandatory=$false)]
        [int]$Maximum = 5,

        [Parameter(Position=2, Mandatory=$false)]
        [int]$Delay = 100
    )

    Begin {
        $cnt = 0
    }

    Process {
        do {
            $cnt++
            try {
                $ScriptBlock.Invoke()
                return
            } catch {
                Write-Error $_.Exception.InnerException.Message -ErrorAction Continue
                Start-Sleep -Milliseconds $Delay
                
            }
        } while ($cnt -lt $Maximum)

        # Throw an error after $Maximum unsuccessful invocations. Doesn't need
        # a condition, since the function returns upon successful invocation.
        throw 'Execution failed.'
    }
}
function CreateNodegroup {
    [CmdletBinding()]
    param (
        $cluster,
        $nodegroup,
        $filePostfix
    )
    
    $nodegroupList = Retry-Command -ScriptBlock {
        eksctl get nodegroups --cluster $cluster -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
    }
    if ($nodegroupList -contains $nodeGroup) {
        $nodegroupExists = $true
    }

    if ($nodegroupExists) {
        Write-Information "nodegroup $nodeGroup was found." -InformationAction Continue
    }
    else {
        Write-Information "nodegroup $nodeGroup was not found, creating it" -InformationAction Continue
        Retry-Command -ScriptBlock { 
            eksctl create nodegroup -f "./nodegroups/${nodegroup}_node_group.yaml$filepostfix" | Out-Null
        }
        $result = ValidateNodegroup -cluster $cluster -nodegroup $nodegroup
        return $result
    }
}
function ValidateK8SObject {
    [CmdletBinding()]
        param (
           $namespace,
           $Object,
           $kubePath
        )
    $namespaceExists = ValidateK8sNamespace -namespace $namespace -kubePath $kubePath
    if ( $namespaceExists ) {
        $rawObject= ($Object -split "/")[1]
        $results  = Retry-Command -ScriptBlock { 
            kubectl get $Object -n $namespace --kubeconfig $kubePath
        }
        foreach ($result in $results) {
            if ($result -match $rawObject) {return $true}
        }
    }
    return $false
}
function ValidateK8SNamespace {
    [CmdletBinding()]
        param (
            $namespace,
            $kubePath
        )
    $namespaces = Retry-Command -ScriptBlock {
        kubectl get namespaces --kubeconfig $kubePath
    }
    foreach ($ns in $namespaces) {
        if ($ns -match $namespace) { return $true }
    }
    return $false
}
function ValidateNodegroup {
    [CmdletBinding()]
        param (
            $cluster,
            $nodegroup
        )
    $nodegroupList =  Retry-Command -ScriptBlock {
        eksctl get nodegroups --cluster $cluster -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
    }
    if ($nodegroupList -contains $nodegroup) {
        $nodegroupExists = $true
    }

    if ($nodegroupExists) {
        Write-Debug "nodegroup $nodegroup was found." -InformationAction Continue
        return $true
    }
    else {
        Write-Debug "nodegroup $nodegroup was not found" -InformationAction Continue
        return $false
    }
}
function CreateK8SNamespace {
    [CmdletBinding()]
    param (
        $namespace,
        $kubePath
    )
    $namespaceExists = ValidateK8SNamespace -namespace $namespace -kubePath $kubePath
    if (! $namespaceExists) {
        Retry-Command -ScriptBlock {
            kubectl create namespace $namespace --kubeconfig $kubePath 
        } | Out-Null
        $namespaceExists = ValidateK8SNamespace -namespace $namespace -kubePath $kubePath
    }
    return $namespaceExists
}
function CreateKubeConfig {
    param (
        $cluster,
        $region,
        $kubePath
    )
    $clustersList =  Retry-Command -ScriptBlock {
        eksctl get clusters -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
    }
    if ($clustersList -contains $cluster) {
        $clusterExists = $true
    }
    if ($clusterExists) {
        Retry-Command -ScriptBlock {
            aws eks --region $region update-kubeconfig --name $cluster --kubeconfig $kubePath | Out-Null
        }
    }
    else {
        Write-Error "cluster $cluster was not found"
        return $false
    }
    return $true
}

function AddArrayItems([String]$ArrayString, $Delimiter, $BaseArray){
  $Array = StrToArray $Delimiter $ArrayString
  $BaseArray += $Array
  return $BaseArray
}

function AddProperties([String] $OuterDelimiter,[String] $InnerDelimiter,[String]$ItemsToAdd, $BaseObject){
  if(!$BaseObject){
    $BaseObject = New-Object PSObject
  }
  $Properties = StrToArray $OuterDelimiter $ItemsToAdd
  foreach ($Property in $Properties) {
   $Split = StrToArray $InnerDelimiter $Property
   $BaseObject | Add-Member -MemberType NoteProperty -Name $Split[0] -Value $Split[1]
 }
 return $BaseObject
}

function StrToArray([String] $Delimiter, [String]$StringToParse) {
  return $StringToParse.split($Delimiter)
}