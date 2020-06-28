Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'
Using module '$PSScriptRoot/../../common/parent.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'


class HelmChartProperties {
  [GenericNodeGroup]$nodeGroup
  [CoreDNS]$DNS
  [Namespace]$namespace
  [String]$name
  [String]$chart
  [String]$repoUrl
  [String]$region
  [String]$valuesFilepath
  [String]$workingFolder
}

class HelmChart: Parent {
  [HelmChartProperties]$helmChartProperties
  HelmChart([HelmChartProperties]$HelmChartProperties): base($HelmChartProperties.workingFolder){
    Write-Host "HelmChart: $PSScriptRoot"
    $this.helmChartProperties = $HelmChartProperties
  }
  InstallHelmChart(){
    $upgrade = $this.CheckIfHelmInstalled()
    if($upgrade){
      $verb = "upgrade"
    } else {
      $verb = "install"
      $this.helmChartProperties.nodeGroup.CreateNodeGroup()
      $this.helmChartProperties.namespace.CreateNamespace()
    }
    helm repo add stable "https://kubernetes-charts.storage.googleapis.com"
    helm repo update
    helm $verb --wait --timeout 3600s $this.helmChartProperties.name $this.helmChartProperties.chart -f $this.helmChartProperties.valuesFilepath -n $this.helmChartProperties.namespace.namespace
    if(!$upgrade){
      $this.helmChartProperties.DNS.AddEntry()
    }
  }

  UninstallHelmChart(){
    if($this.CheckIfHelmInstalled()){
      helm uninstall $this.helmChartProperties.name -n $this.helmChartProperties.namespace.namespace
    } else {
     Write-Host "Helmchart: $($this.helmChartProperties.name) doens't exists in NS: $($this.helmChartProperties.namespace.namespace)"
    }
    $this.helmChartProperties.DNS.DeleteEntry()
    $this.helmChartProperties.namespace.DeleteNamespace()
    # Need to find the correct time to delete the node
    $this.helmChartProperties.nodeGroup.DeleteNodeGroup()
  }

  [bool]CheckIfHelmInstalled(){
    $helmChartStatus = (helm status $this.helmChartProperties.name -n $this.helmChartProperties.namespace.namespace -o json| Out-String | ConvertFrom-Json)
    if(($helmChartStatus) -And ($helmChartStatus.info.status -eq "deployed")) {
      return $true
    } else {
      return $false
    }
  }



}
