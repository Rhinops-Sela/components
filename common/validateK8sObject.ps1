#!/bin/pwsh
#region Cluster
param (
    [Alias("Namespace")] $ns,
    [Alias("K8SObject")] $Object,
    [Alias("KubeConfigName")] $kubePath
)

$namespaceExists
$namespaceExists= Invoke-Expression "../common/validateK8sNamespace.ps1 -Namespace $ns -KubeConfigName $kubePath"

if ( $namespaceExists ) {
    $rawObject= ($Object -split "/")[1]
    $results=Invoke-Expression "kubectl get $Object -n $ns --kubeconfig $kubePath"
    foreach ($result in $results) {
        if ($result -match $Object) {return $true}
    }
}
return $false