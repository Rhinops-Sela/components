class Namespace {
  [String]$namespace
  [String]$kubePath
  Namespace([String]$namespace,[String]$kubePath)
  {
    $this.namespace = $namespace
    $this.kubePath = $kubePath
  }
  CreateNamespace(){
    $result = $this.VerifyNamespaceExists()
    if(!$result){
      Write-Host "Createing namespace $($this.namespace)"
      kubectl create namespace $this.namespace --kubeconfig $this.kubePath
    } else {
      Write-Host "Namespace $($this.namespace) already exists"
    }
  }

  DeleteNamespace([String]$namespace,[String]$kubePath){
    $result = $this.VerifyNamespaceExists()
    if($result){
      Write-Host "Deleting namespace $($this.namespace)"
      kubectl delete namespace $this.namespace
    } else {
      Write-Host "Namespace $($this.namespace) doesn't exists"
    }
  }

  [bool]VerifyNamespaceExists(){
    $namespaces = kubectl get namespaces --kubeconfig $this.kubePath
    foreach ($ns in $namespaces) {
        if ($ns -match $this.namespace) {
          return $true
        }
    }
    return $false
  }
}