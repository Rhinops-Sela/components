Using module '$PSScriptRoot/../../common/parent.psm1'
class HelmChartProperties {
  [String]$name
  [String]$chart
  [String]$namespace
  [String]$repoUrl
  [String]$region
  [String]$valuesFilepath
  [String]$workingFolder
  [bool]$deployed
}
class HelmChart: Parent {
  [HelmChartProperties]$helmChartProperties
  HelmChart([HelmChartProperties]$HelmChartProperties): base($helmChartProperties.workingFolder){
    $this.helmChartProperties = $HelmChartProperties
  }
  InstallHelmChart(){
    $this.CheckIfHelmInstalled()
    if($this.helmChartProperties.deployed){
      $this.Install($true)
    } else {
      $this.Install($false)
    }
  }

  UninstallHelmChart(){
    $this.CheckIfHelmInstalled()
    if($this.helmChartProperties.deployed){
      helm uninstall --debug $this.helmChartProperties.name -n $this.helmChartProperties.namespace
    } else {
     Write-Host "Helmchart: $($this.helmChartProperties.name) doens't exists in NS: $($this.helmChartProperties.namespace)"
    }
  }

  CheckIfHelmInstalled(){
    $helmChartStatus = (helm status $this.helmChartProperties.name -n $this.helmChartProperties.namespace -o json| Out-String | ConvertFrom-Json)
    if(($helmChartStatus) -And ($helmChartStatus.info.status -eq "deployed")) {
      $this.helmChartProperties.deployed = $true
    } else {
      $this.helmChartProperties.deployed = $false
    }
  }
  
  Install([bool]$upgrade){
    $verb = "install"
    if($upgrade){
      $verb = "upgrade"
    }
    helm repo add stable "https://kubernetes-charts.storage.googleapis.com"
    helm repo update
    helm $verb --wait --debug --timeout 3600s $this.helmChartProperties.name $this.helmChartProperties.chart -f $this.helmChartProperties.valuesFilepath -n $this.helmChartProperties.namespace
  }
}
