Using module '$PSScriptRoot/../../common/parent.psm1'
Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'


class HelmChartProperties {
  [String]$name
  [String]$chart
  [String]$namespace
  [String]$repoUrl
  [String]$region
  [String]$valuesFilepath
  [String]$workingFolder
  [GenericNodeGroup]$nodeGroup
  [String]$dnsTarget
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
      $DNS = [CoreDNS]::new($this.helmChartProperties.dnsTarget,$this.workingFolder)
      $DNS.DeleteEntry()
      $Namespace = [Namespace]::new($this.helmChartProperties.namesapce, $this.workingFolder)
      $Namespace.DeleteNamespace()
      $this.helmChartProperties.nodeGroup.DeleteNodeGroup()
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

  PreInstall(){
    $this.helmChartProperties.nodeGroup.CreateNodeGroup()
    $namespace = [Namespace]::new($this.helmChartProperties.namesapce, $this.workingFolder)
    $namespace.CreateNamespace()

  }

  PostInstall(){
    $DNS = [CoreDNS]::new($this.helmChartProperties.dnsTarget,$this.workingFolder)
    $DNS.AddEntry()
  }

  Install([bool]$upgrade){
    if($upgrade){
      $verb = "upgrade"
    } else {
      $verb = "install"
      $this.PreInstall()
    }
    helm repo add stable "https://kubernetes-charts.storage.googleapis.com"
    helm repo update
    helm $verb --wait --debug --timeout 3600s $this.helmChartProperties.name $this.helmChartProperties.chart -f $this.helmChartProperties.valuesFilepath -n $this.helmChartProperties.namespace
    if(!$upgrade){
      $this.PostInstall()
    }
  }
}
