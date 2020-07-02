#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/monitoring-nodegroup.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

Set-Location -Path $PSScriptRoot
$workingFolder= "$PSScriptRoot"
$HelmChart = [HelmChart]::new(@{
  name = "prometheus"
  namespace = [Namespace]::new("monitoring", $workingFolder)
  workingFolder = $workingFolder
  nodeGroup = [MonitoringNodeGroup]::new($workingFolder)
}, $true)
$HelmChart.UninstallHelmChart()

$DNS = [CoreDNS]::new($workingFolder)
$DNS.DeleteEntries(
                  @(
                    @{
                      Source = "prometheus.monitoring.svc.cluster.local"
                      Target = "${SERVER_DNS_RECORD}"
                    },
                    @{
                      Source = "prometheus-alertmanager.monitoring.svc.cluster.local"
                      Target = "${ALERTMANAGER_RECORD}"
                    }
                  )
                )

<#
#If prev helm uninstall fails
kubectl delete clusterrole prometheus-alertmanager && \
kubectl delete clusterrole prometheus-pushgateway && \
kubectl delete clusterrole prometheus-server && \
kubectl delete clusterrole prometheus-kube-state-metrics && \
kubectl delete ClusterRoleBinding prometheus-kube-state-metrics && \
kubectl delete ClusterRoleBinding prometheus-alertmanager && \
kubectl delete ClusterRoleBinding prometheus-pushgateway && \
kubectl delete ClusterRoleBinding prometheus-server
#>