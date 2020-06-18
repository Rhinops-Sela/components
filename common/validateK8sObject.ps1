#!/bin/pwsh
#region Cluster
param (
    [Alias("Namespace")] $ns,
    [Alias("K8SObject")] $Object,
    [Alias("KubeConfigFullName")] $kubePath
)

$namespaceExists= Invoke-Expression "$./components/common/validateK8sNamespace.ps1 -Namespace $ns -KubeConfigFullName $kubePath"
if ( $namespaceExists ) {
    $rawObject= ($Object -split "/")[1]
    $results=kubectl get $Object -n $ns --kubeconfig "$kubePath"
    foreach ($result in $results) {
        if ($result -match $rawObject) {return $true}
    }
}
return $false