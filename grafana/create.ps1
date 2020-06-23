#!/bin/pwsh
$debug='${NAME}'
Set-Location -Path $PSScriptRoot
. ../common/node-groups.ps1
if ($debug -Match 'NAME'){
    $requestedDashboards = 'label1=value1;label2=value2'
    $requestedUrl = 't3.small,t2.small'
    $reqeustedNamespace = 'taint1=true:NoSchedule;taint2=true:NoSchedule'
}
else {
    aws configure set aws_access_key_id $Env:AWS_ACCESS_KEY_ID
    aws configure set aws_secret_access_key $Env:AWS_SECRET_ACCESS_KEY
    aws configure set region $Env:AWS_DEFAULT_REGION
    $requestedDashboards = '${DASHNOARDS}'
    $requestedUrl = '${PERSISTANT_DATA}'
    $reqeustedNamespace = '${DNS_RECORD}'
}