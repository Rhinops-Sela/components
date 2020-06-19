function CreateNodegroup {
    param (
        [Alias("NodegroupName")] $nodeGroup,
        [Alias("Postfix")] $filepostfix
    )

    $nodegroupList = eksctl get nodegroups --cluster $lookUpCluster -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
    if ($nodegroupList -contains $nodeGroup) {
        $nodegroupExists = $true
    }

    if ($nodegroupExists) {
        Write-Host "nodegroup $nodeGroup was found."
    }
    else {
        Write-Host "nodegroup $nodeGroup was not found, creating it"
        eksctl create nodegroup -f "./nodegroups/${nodeGroup}_node_group.yaml$filepostfix"
    }
}
function ValidateK8SObject {
    param (
        [Alias("Namespace")] $ns,
        [Alias("K8SObject")] $Object,
        [Alias("KubeConfigName")] $kubePath
    )
    $namespaceExists= ValidateK8sNamespace -Namespace $ns -KubeConfigName $kubePath
    if ( $namespaceExists ) {
        $rawObject= ($Object -split "/")[1]
        $results=Invoke-Expression "kubectl get $Object -n $ns --kubeconfig $kubePath"
        foreach ($result in $results) {
            if ($result -match $rawObject) {return $true}
        }
    }
    return $false
}
function ValidateK8SNamespace {
    param (
        [Alias("Namespace")] $ns,
        [Alias("KubeConfigName")] $kubePath
    )

    $namespaces = kubectl get namespaces --kubeconfig "$kubePath"
    $namespaceExists=$false

    foreach ($namespace in $namespaces) {
        if ($namespace -match $ns) { return $true }
    }
    return $false
}
function ValidateNodegroup {
    param (
        [Alias("ClusterName")] $lookUpCluster,
        [Alias("NodegroupName")]  $nodegroup
    )

    $noderoupExists = $false
    $nodegroupList = eksctl get nodegroups --cluster $lookUpCluster -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
    if ($nodegroupList -contains $nodegroup) {
        $noderoupExists = $true
    }

    if ($noderoupExists) {
        Write-Host "nodegroup $nodegroup was found."
        return $true
    }
    else {
        Write-Error "nodegroup $nodegroup was not found"
        return $false
    }
}
function CreateK8SNamespace {
    param (
    [Alias("Namespace")] $ns,
    [Alias("KubeConfigName")] $kubePath
    )

    $namespaces = kubectl get namespaces --kubeconfig "$kubePath"
    $namespaceExists=$false

    foreach ($namespace in $namespaces) {
        if ($namespace -match $ns) { return $true }
    }
    kubectl create namespace $ns --kubeconfig "$kubePath"
    return $true
}
function CreateKubeConfig {
    param (
        [Alias("ClusterName")] $lookUpCluster,
        [Alias("ClusterRegion")] $lookUpRegion,
        [Alias("Nodegroup")]  $nodegroupName, 
        [Alias("KubeConfigName")] $kubePath
    )
    $clusterExists = $false
    $clustersList = eksctl get clusters -o json | ConvertFrom-Json | Select-Object -ExpandProperty Name
    if ($clustersList -contains $lookUpCluster) {
        $clusterExists = $true
    }
    if ($clusterExists) {
        aws eks --region $lookUpRegion update-kubeconfig --name $lookUpCluster --kubeconfig "$kubePath"
    }
    else {
        Write-Error "cluster $lookUpCluster was not found"
        return $false
    }
    return $true
}