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
    $results
    Write-Host "before"
    try {
          $results=Invoke-Expression "kubectl get $Object -n $ns --kubeconfig $kubePath"
    }
    catch {}
    Write-Host "after"
    foreach ($result in $results) {
        if ($result -match $Object) {return $true}
    }
}
return $false