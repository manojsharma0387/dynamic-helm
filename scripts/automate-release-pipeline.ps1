param(
    [Parameter(Mandatory = $true)]
    [string] $organizationName,

    [Parameter(Mandatory = $true)]
    [string] $projectName,

    [Parameter(Mandatory = $true)]
    [string] $jsonPath,

    [Parameter(Mandatory = $true)]
    [string] $application
)

TRY
{
    $webClient = New-Object Net.WebClient
    #$token = "Bearer $env:SYSTEM_ACCESSTOKEN"
    #$AzureDevOpsAuthenicationHeader = @{ Authorization = $token }
    $AzureDevOpsPAT = "exfxupc27amglwx2jk3qs62yeynmrvmfkvxy4whwsrpgrfndrkhq"
    $AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($AzureDevOpsPAT)")) }          
    $releaseDefinitionName = "$application"+"-cd"
    $url = "https://vsrm.dev.azure.com/$organizationName/$projectName/_apis/release/definitions?api-version=5.0"
    write-host "URL is $url"

    $response = (Invoke-RestMethod -Uri $url -Method get -Headers $AzureDevOpsAuthenicationHeader).value | Where-Object{$_.name -eq "$releaseDefinitionName"}

    write-host "Response = $response"

    $pipelineName = $response.name
    IF($pipelineName -eq "$releaseDefinitionName")
    {
        Write-Host "Pipeline is already exists: $pipelineName"
    }
    ELSE
    {
        $body = Get-Content -Path "$jsonPath"
        $result = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -Headers $AzureDevOpsAuthenicationHeader
    }
}
CATCH [Exception]
{
    write-host $_.Exception
    throw $_.Exception
}