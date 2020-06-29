Using module '$PSScriptRoot/../../common/parent.psm1'
class DNSRecord {
  [String]$Source
  [String]$Target
}
class CoreDNS: Parent{
  $namespace = "kube-system"
  $templatePath = ""
  $workingFolder
  CoreDNS([String]$workingFolder):base($workingFolder){
    $this.templatePath = "$PSScriptRoot/templates/coredns-configmap.json"
    $this.workingFolder = $workingFolder
  }

  AddEntries([DNSRecord[]]$dnsRecords){
    foreach($dnsRecord in $dnsRecords){
      Write-Host "Adding record: Source: $($dnsRecord.Source) Target: $($dnsRecord.Target)"
      $lineToReplace = "\n    rewrite name fennec.io fennec.io\n"
      $newLine = "\n    rewrite name $($dnsRecord.Source) $($dnsRecord.Target)\n    rewrite name fennec.io fennec.io\n"
      $this.ModifyEntry($lineToReplace, $newLine)
    }
  }
  DeleteEntries([DNSRecord[]]$dnsRecords){
    foreach($dnsRecord in $dnsRecords){
      $lineToReplace = "    rewrite name $($dnsRecord.Source) $($dnsRecord.Target)\n"
      $this.ModifyEntry($lineToReplace, "")
    }
  }

  ModifyEntry([String]$lineToReplace,[String]$newLine){
    $configFile = $this.GetCoreDNSData()
    $configFile = $configFile.replace($lineToReplace, $newLine)
    $configFile = $configFile | ConvertFrom-Json
    $configFileTemplate = (Get-Content $this.templatePath | Out-String | ConvertFrom-Json)
    $configFileTemplate.data.Corefile = $configFile.data.Corefile
    $configFileTemplate | ConvertTo-Json -depth 100 | Out-File "$($this.workingFolder)/coredns-configmap-execute.json"
    kubectl apply -f "$($this.workingFolder)/coredns-configmap-execute.json" -n $this.namespace
    kubectl delete pods -l  k8s-app=kube-dns -n $this.namespace
  }

  [psobject]GetCoreDNSData(){
    $configMap = (kubectl get configmaps coredns -o json -n $this.namespace)
    return $configMap
  }
}