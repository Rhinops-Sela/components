. $PSScriptRoot/../helper.ps1

 class HelmChart {
    [String]$name
    [String]$chart
    [String]$namespace
    [String]$repoUrl
    [String]$region
    [String]$valuesFilepath
    [bool]$deployed
 }

function InstallHelmChart([HelmChart]$HelmChart){
  $helmChart = CheckIfHelmInstalled $HelmChart
  Write-Host $helmChart
}
function DeleteHelmChart([HelmChart]$HelmChart){}
function UpgradeHelmDeployment([HelmChart]$HelmChart){}
function CheckIfHelmInstalled([HelmChart]$HelmChart){
  $helmChartStatus = (helm status $HelmChart.name -n $HelmChart.namespace | Out-String | ConvertFrom-Json)
  if($helmChartStatus.info.status == "deployed") {
   $HelmChart.deployed = $true
  } else {
    $HelmChart.deployed = $false
  }
  return $HelmChart
}




