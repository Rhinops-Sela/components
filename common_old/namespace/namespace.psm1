Using module '$PSScriptRoot/../../common/parent.psm1'
class Namespace: Parent {
  [String]$namespace
  Namespace([String]$namespace,[String]$workingFolder):base($workingFolder)
  {
    $this.namespace = $namespace
  }
  CreateNamespace(){
    $result = $this.VerifyNamespaceExists()
    if(!$result){
      Write-Host "Createing namespace $($this.namespace)"
      $this.ExecuteCommand("create")
    } else {
      Write-Host "Namespace $($this.namespace) already exists"
    }
  }

  DeleteNamespace(){
    $result = $this.VerifyNamespaceExists()
    if($result){
      Write-Host "Deleting namespace $($this.namespace)"
      $this.ExecuteCommand("delete")
    } else {
      Write-Host "Namespace $($this.namespace) doesn't exists"
    }
  }

  ExecuteCommand([String]$verb){
    kubectl $verb namespace $this.namespace
  }

  [bool]VerifyNamespaceExists(){
    $namespaces = kubectl get namespaces
    foreach ($ns in $namespaces) {
        if ($ns -match $this.namespace) {
          return $true
        }
    }
    return $false
  }
}