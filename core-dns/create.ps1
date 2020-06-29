#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/monitoring-nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

$workingFolder= "$PSScriptRoot"
Write-Host "Core-DNS - PSScriptRoot: $workingFolder"
$DNS = [CoreDNS]::new($workingFolder)
if($DNS.debug){
  $DNSRecords=@(
    @{
        Source = "debug.fennec.svc.cluster.local"
        Target = "debug.fennec.io"
      }
  )
  $DNS.AddEntries($DNSRecord)
} else {
  $DNSRecords = @()
  foreach($domainRecord in "${DNS_RECORDS}".Split(";")){
    $domainRecordArr = $domainRecord.Split("=")
    $DNSRecords += @{
        Source = $domainRecordArr[0]
        Target = $domainRecordArr[1]
      }
  }
  $DNS.AddEntries($DNSRecords)
}



