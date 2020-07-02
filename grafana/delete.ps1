#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/monitoring-nodegroup.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

Set-Location -Path $PSScriptRoot
$workingFolder= "$PSScriptRoot"
$HelmChart = [HelmChart]::new(@{
  name = "grafana"
  namespace = [Namespace]::new("monitoring", $workingFolder)
  workingFolder = $workingFolder
  nodeGroup = [MonitoringNodeGroup]::new($workingFolder)
}, $true)
$HelmChart.UninstallHelmChart()
$source = "${DNS_RECORD}"
if($HelmChart.debug){
 $source = "grafana.fennec.io"
}

$DNS = [CoreDNS]::new($workingFolder)
$DNS.DeleteEntries(
                  @(
                    @{
                      Source = "$source"
                      Target = "grafana.monitoring.svc.cluster.local"
                    }
                  )
                )
<#
#If prev helm uninstall fails
kubectl delete PodSecurityPolicy grafana && \
kubectl delete PodSecurityPolicy grafana-test && \
kubectl delete clusterrole grafana-clusterrole && \
kubectl delete ClusterRoleBinding grafana-clusterrolebinding
#>