param ([String]$subscription,[String]$service,[String]$storageaccountname,[String]$slot,[String]$package,[String]$configuration,[String]$publishsettings)

Import-Module Azure -DisableNameChecking -ErrorAction SilentlyContinue

# Remove Azure Profiles

$AzureProfiles = Get-AzureAccount
Foreach ($AzureProfile in $AzureProfiles)
{

  Remove-AzureAccount -Name $AzureProfile.ID -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

}
#

$ErrorActionPreference = "Stop"
$timeStampFormat = "g"

Write-Output "Import Publish Settings"
Import-AzurePublishSettingsFile $publishsettings

function PublishDeployment(){
 Write-Output "$(Get-Date -f $timeStampFormat) - Publising Azure Deployment..."
 $deployment = Get-AzureDeployment -ServiceName $service -Slot $slot -ErrorVariable a -ErrorAction silentlycontinue 

 if ($a[0] -ne $null) {
    Write-Output "$(Get-Date -f $timeStampFormat) - No deployment is detected. Creating a new deployment. "
 }
 
 if ($deployment.Name -ne $null) {
    Write-Output "$(Get-Date -f $timeStampFormat) - Deployment exists in $service.  Upgrading deployment."    
	RemoveDeployment
	NewDeployment
 } else {
    NewDeployment
 }
}

function NewDeployment()
{
    write-progress -id 3 -activity "Creating New Deployment" -Status "In progress"
    Write-Output "$(Get-Date -f $timeStampFormat) - Creating New Deployment: In progress"

    $opstat = New-AzureDeployment -Slot $slot -Package $package -Configuration $configuration -ServiceName $service

    $completeDeployment = Get-AzureDeployment -ServiceName $service -Slot $slot
    $completeDeploymentID = $completeDeployment.deploymentid

    write-progress -id 3 -activity "Creating New Deployment" -completed -Status "Complete"
    Write-Output "$(Get-Date -f $timeStampFormat) - Creating New Deployment: Complete, Deployment ID: $completeDeploymentID"
}

function RemoveDeployment()
{
    write-progress -id 3 -activity "Remove Deployment" -Status "In progress"
    Write-Output "$(Get-Date -f $timeStampFormat) - Remove Deployment: In progress"

    $removedeployment = Remove-AzureDeployment -ServiceName $service -Slot $slot -DeleteVHD -Force

}


#Publish Deployment
try{
    Set-AzureSubscription -CurrentStorageAccount $storageaccountname -SubscriptionName $subscription    
    PublishDeployment
}catch{
    throw 
    Break
}