[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]
    $LabVMId
)

do {
    $labVmComputeId = (Get-AzResource -Id $LabVMId).Properties.ComputeId
    Start-Sleep -Seconds 10
}
while (-not $labVmComputeId)

# Get lab VM resource group name
$labVmRgName = (Get-AzResource -Id $labVmComputeId).ResourceGroupName

# Get the lab VM Name
$labVmName = (Get-AzResource -Id $LabVMId).Name

# Get lab VM public IP address
$labVMIpAddress = (Get-AzPublicIpAddress -ResourceGroupName $labVmRgName -Name $labVmName).IpAddress

# Get lab VM FQDN
$labVMFqdn = (Get-AzPublicIpAddress -ResourceGroupName $labVmRgName -Name $labVmName).DnsSettings.Fqdn

Write-Host "Setting Lab Resource Group Name Var: $labVmRgName"
Write-Host "##vso[task.setvariable variable=ChocoCIClient.labVmRgName;]$labVmRgName"

Write-Host "Setting Lab VM IP Address Var: $labVMIpAddress"
Write-Host "##vso[task.setvariable variable=ChocoCIClient.labVMIpAddress;]$labVMIpAddress"

Write-Host "Setting Lab VM FQDN Var: $labVMFqdn"
Write-Host "##vso[task.setvariable variable=ChocoCIClient.labVMFqdn;]$labVMFqdn"

$CertificateScript = {
    $url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
    $file = "$env:temp\ConfigureRemotingForAnsible.ps1"

    [System.Net.WebClient]::new().DownloadFile($url, $file)

    & $file -Verbose
}

$Script = New-Item -Path ./CertScript.ps1
$CertificateScript | Set-Content -Path $Script.FullName

$params = @{
    ResourceGroupName = 'choco-ci'
    VMName            = $labVMName
    CommandId         = 'RunPowerShellScript'
    ScriptPath        = $Script.FullName
}

Invoke-AzVMRunCommand @params -Verbose
