#!/bin/pwsh
Using module '$PSScriptRoot/../../common/nodegroups/nodegroup.psm1'
Using module '$PSScriptRoot/../../common/namespace/namespace.psm1'
Using module '$PSScriptRoot/../../common/helm/helm.psm1'
Using module '$PSScriptRoot/../../common/core-dns/core-dns.psm1'

$workingFolder= "$PSScriptRoot"
$executeDeploymentFilepath= "$workingFolder/ui-deploymnet-execute.json"
Write-Host "Dynamodb - PSScriptRoot: $workingFolder"
$debug='${NAME}'
if ($debug -Match 'NAME'){
  $instanceTypes = 'c5.large,c5.xlarge'
  $useSpot = 'true'
  $createdNamespace = "dynamodb"
  $spotAllocationStrategy = 'lowest-price'
  $onDenmandInstances = 0
} else
{
  $instanceTypes = '${INSTANCE_TYPES}'
  $useSpot = '${USE_SPOT}'
  $onDenmandInstances = ${ON_DEMEND_BASE_CAPACITY}
  $spotAllocationStrategy = 'lowest-price'
  $createdNamespace = '${NAMESPACE}'
}

$nodeProperties = @{
      nodeGroupName = "dynamodb"
      workingFilePath = "$workingFolder"
      userLabelsStr = 'role=dynamodb'
      instanceTypes = "$instanceTypes"
      taintsToAdd = 'dynamodb=true:NoSchedule'
    }

if($useSpot -eq 'true'){
$nodeProperties.spotProperties = @{
      onDemandBaseCapacity = $onDenmandInstances
      onDemandPercentageAboveBaseCapacity = 0
      spotAllocationStrategy = $spotAllocationStrategy
      useSpot = $useSpot
    }
}

$NodeGroup = [GenericNodeGroup]::new($nodeProperties,"$workingFolder/templates","dynamo-ng-template.json")
$NodeGroup.CreateNodeGroup()
$Namespace = [Namespace]::new("$createdNamespace", $workingFolder)
$Namespace.CreateNamespace()


$adminSource = "${ADMIN_DNS_RECORD}"
$dynamodbSource = "${DYNAMO_DNS_RECORD}"
if($Namespace.debug){
 $adminSource = "dynamodb-admin.fennec.io"
 $dynamodbSource = "dynamodb.fennec.io"
}

$uiDeployment = (Get-Content "$workingFolder/templates/admin/deployment.json" | Out-String | ConvertFrom-Json)
$uiDeployment.spec.template.spec.containers.env.value = "dynamodb-local.$createdNamespace.svc.cluster.local"
$uiDeployment | ConvertTo-Json -depth 100 | Out-File "$executeDeploymentFilepath"

kubectl apply -f "$workingFolder/templates/admin" -n $createdNamespace
kubectl apply -f "$workingFolder/templates/dynamodb" -n $createdNamespace

$DNS = [CoreDNS]::new($workingFolder)
$DNS.AddEntries(
                  @(
                    @{
                      Source = "$adminSource"
                      Target = "dynamodb-local-admin.$createdNamespace.svc.cluster.local"
                    },
                    @{
                      Source = "$dynamodbSource"
                      Target = "dynamodb-local.$createdNamespace.svc.cluster.local"
                    }
                  )
                )
