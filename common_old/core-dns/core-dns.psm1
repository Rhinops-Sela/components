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
    $configFile = $this.GetCoreDNSData()
    $newConfig = @()
    foreach($line in $configFile){
        if($line -match "rewrite name fennec.ai fennec.ai"){
          foreach($dnsRecord in $dnsRecords){
            $newConfig+="        rewrite name $($dnsRecord.Source) $($dnsRecord.Target)"
          }
          $newConfig+="        rewrite name fennec.ai fennec.ai"
        } else {
          $newConfig+=$line
        }
      }
      $this.Apply($newConfig)
  }
  DeleteEntries([DNSRecord[]]$dnsRecords){
    $configFile = $this.GetCoreDNSData()
    $newConfig = @()
    foreach($dnsRecord in $dnsRecords){
      foreach($line in $configFile){
        if($line -match "$($dnsRecord.Source) $($dnsRecord.Target)"){
          Write-Host "Deleting $($dnsRecord.Source) $($dnsRecord.Target)"
        } else {
          $newConfig+=$line
        }
      }
    }
    $this.Apply($newConfig)
  }

  Apply([String[]]$newConfig){
    Set-Content -Path "$($this.workingFolder)/coredns-configmap-execute.yaml" -Value "" -Force
    Set-Content -Path "$($this.workingFolder)/coredns-configmap-execute.yaml" -Value $newConfig -Force
    kubectl apply -f "$($this.workingFolder)/coredns-configmap-execute.yaml" -n $this.namespace
    kubectl delete pods -l  k8s-app=kube-dns -n $this.namespace
  }
  [psobject]GetCoreDNSData(){
    $configMap = (kubectl get configmaps coredns -o yaml -n $this.namespace)
    return $configMap
  }
}