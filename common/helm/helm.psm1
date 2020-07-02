Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'
Using module '$PSScriptRoot/../../common/parent.psm1'


class HelmChartProperties {
  [GenericNodeGroup]$nodeGroup
  [Namespace]$namespace
  [String]$name
  [String]$chart
  [String]$repoUrl
  [String]$region
  [String]$valuesFilepath
  [String]$workingFolder
}

class HelmChart: Parent {
  [String]$verb
  [bool]$upgrade
  [HelmChartProperties]$helmChartProperties
  HelmChart([HelmChartProperties]$HelmChartProperties, [bool]$Uninstall): base($HelmChartProperties.workingFolder){
    if($Uninstall){
      $this.helmChartProperties = $HelmChartProperties
      if($this.helmChartProperties.repoUrl){
        helm repo add stable $this.helmChartProperties.repoUrl
      }
    }
  }
  HelmChart([HelmChartProperties]$HelmChartProperties): base($HelmChartProperties.workingFolder){
    $this.helmChartProperties = $HelmChartProperties
    $this.upgrade = $this.CheckIfHelmInstalled()
    if($this.upgrade){
        $this.verb = "upgrade"
        Write-Host "Upgrading Helm Chart: $($this.helmChartProperties.name)"
      } else {
        $this.verb = "install"
        Write-Host "Deploying Helm Chart: $($this.helmChartProperties.name)"
        if($this.helmChartProperties.nodeGroup ){
          $this.helmChartProperties.nodeGroup.CreateNodeGroup()
        }
        if($this.helmChartProperties.namespace){
          $this.helmChartProperties.namespace.CreateNamespace()
        }
      }
      if($this.helmChartProperties.repoUrl){
        Write-Host "helm repo add stable $($this.helmChartProperties.repoUrl)"
        helm repo add stable $this.helmChartProperties.repoUrl
      }
  }

  InstallHelmChart(){
    Write-Host "helm repo update"
    helm repo update
    Write-Host "helm $($this.verb) --wait --timeout 3600s $($this.helmChartProperties.name) $($this.helmChartProperties.chart) -f $($this.helmChartProperties.valuesFilepath) -n $($this.helmChartProperties.namespace.namespace)"
    helm $this.verb --wait --timeout 3600s $this.helmChartProperties.name $this.helmChartProperties.chart -f $this.helmChartProperties.valuesFilepath -n $this.helmChartProperties.namespace.namespace

  }

  UninstallHelmChart(){
    if($this.CheckIfHelmInstalled()){
      helm uninstall $this.helmChartProperties.name -n $this.helmChartProperties.namespace.namespace
    } else {
     Write-Host "Helmchart: $($this.helmChartProperties.name) doens't exists in NS: $($this.helmChartProperties.namespace.namespace)"
    }
    $this.helmChartProperties.namespace.DeleteNamespace()
    # Need to find the correct time to delete the node
    $this.helmChartProperties.nodeGroup.DeleteNodeGroup()
  }

  [bool]CheckIfHelmInstalled(){
    $helmReleseExists = $false
    $helmList = helm ls --all-namespaces -o json | ConvertFrom-Json | Select-Object -ExpandProperty NAME
    if ($helmList -contains $this.helmChartProperties.name ) {
        $helmReleseExists = $true
    }

    if ($helmReleseExists) {
        Write-Host "helm $($this.helmChartProperties.name ) was found."
        return $true
    }
    else {
        Write-Host "helm $($this.helmChartProperties.name ) was not found"
        return $false
    }
  }

<#   [bool]CheckIfHelmInstalled(){
    $helmChartStatus = (helm status $this.helmChartProperties.name -n $this.helmChartProperties.namespace.namespace --stderrthreshold 0 -o json| Out-String | ConvertFrom-Json)
    if(($helmChartStatus) -And ($helmChartStatus.info.status -eq "deployed")) {
      return $true
    } else {
      return $false
    } #>
}




