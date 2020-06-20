function CreateNodegroup {
    [CmdletBinding()]
        param (
            $cluster,
            $nodegroup,
            $filePostfix
        )
    $nodegroupList = eksctl get nodegroups --cluster $cluster -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
    if ($nodegroupList -contains $nodeGroup) {
        $nodegroupExists = $true
    }

    if ($nodegroupExists) {
        Write-Information "nodegroup $nodeGroup was found." -InformationAction Continue
    }
    else {
        Write-Information "nodegroup $nodeGroup was not found, creating it" -InformationAction Continue
        $result = eksctl create nodegroup -f "./nodegroups/${nodegroup}_node_group.yaml$filepostfix"
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
    $namespaceExists = ValidateK8sNamespace $namespace $kubePath
    if ( $namespaceExists ) {
        $rawObject= ($Object -split "/")[1]
        $results=Invoke-Expression "kubectl get $Object -n $namespace --kubeconfig $kubePath"
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
    $namespaces = kubectl get namespaces --kubeconfig "$kubePath"
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
    $nodegroupExists = $false
    $nodegroupList = eksctl get nodegroups --cluster $cluster -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
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
        $result=kubectl create namespace $namespace --kubeconfig "$kubePath"
    }
    $namespaceExists = ValidateK8SNamespace -namespace $namespace -kubePath $kubePath
    return $namespaceExists
}
function CreateKubeConfig {
    param (
        $cluster,
        $region,
        $kubePath
    )
    $clustersList = eksctl get clusters -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
    if ($clustersList -contains $cluster) {
        $clusterExists = $true
    }
    if ($clusterExists) {
        aws eks --region $region update-kubeconfig --name $cluster --kubeconfig "$kubePath"
    }
    else {
        Write-Error "cluster $cluster was not found"
        return $false
    }
    return $true
}