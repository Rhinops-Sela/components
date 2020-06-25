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
        
        Write-Host "CreateNodegroup: eksctl get nodegroups --cluster $cluster -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name"
        eksctl get nodegroups --cluster $cluster -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
        Write-Host "CreateNodegroup: success"

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
            Write-Host "CreateNodegroup: eksctl create nodegroup -f ./nodegroups/${nodegroup}_node_group.yaml$filepostfix | Out-Null"
            eksctl create nodegroup -f "./nodegroups/${nodegroup}_node_group.yaml$filepostfix" | Out-Null
            Write-Host "CreateNodegroup: success"
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
            Write-Host "ValidateK8SObject: kubectl get $Object -n $namespace --kubeconfig $kubePath"
            kubectl get $Object -n $namespace --kubeconfig $kubePath
            Write-Host "ValidateK8SObject: success"

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
        Write-Host "ValidateK8SNamespace: kubectl get namespaces --kubeconfig $kubePath"
        kubectl get namespaces --kubeconfig $kubePath
        Write-Host "ValidateK8SNamespace: Success"

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
        Write-Host "ValidateNodegroup: eksctl get nodegroups --cluster $cluster -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name"
        eksctl get nodegroups --cluster $cluster -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
        Write-Host "ValidateNodegroup: success"

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
            Write-Host "CreateK8SNamespace: kubectl create namespace $namespace --kubeconfig $kubePath "
            kubectl create namespace $namespace --kubeconfig $kubePath 
            Write-Host "CreateK8SNamespace: success"
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
        Write-Host "CreateKubeConfig: eksctl get clusters -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name "
        eksctl get clusters -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
        Write-Host "CreateKubeConfig: Success "
    }

    if ($clustersList -contains $cluster) {
        $clusterExists = $true
    }
    if ($clusterExists) {
        Retry-Command -ScriptBlock {
            Write-Host "CreateKubeConfig: aws eks --region $region update-kubeconfig --name $cluster --kubeconfig $kubePath | Out-Null"
            aws eks --region $region update-kubeconfig --name $cluster --kubeconfig $kubePath | Out-Null
            Write-Host "CreateKubeConfig: success"
        }
    }
    else {
        Write-Error "cluster $cluster was not found"
        return $false
    }
    return $true
}

