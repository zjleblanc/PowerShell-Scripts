param(
	[string] [Parameter(Mandatory=$true)] $ResourceGroupName,
	[string] [Parameter(Mandatory=$true)] $SiteName,
	[string] [Parameter(Mandatory=$false)] $Slot,
	#Assumes comma separated key-value pairs in $InputFile
	[string] [Parameter(Mandatory=$false)] $InputFile = ".\AppSettings.txt"
)

#Get Production or staging slot based on $Slot
if ($Slot -eq [string]::Empty)
{
	$Site = Get-AzureRmWebApp -ResourceGroupName $ResourceGroupName -Name $SiteName
}
else 
{
	$Site = Get-AzureRmWebAppSlot -ResourceGroupName $ResourceGroupName -Name $SiteName -Slot $Slot
}

$AppSettingsHash = @{}
#Get existing app settings
foreach ($kvp in $Site.SiteConfig.AppSettings)
{
	$AppSettingsHash[$kvp.Name] = $kvp.Value
}

#Get app settings from file to import
Get-Content $InputFile | Foreach-Object {
	$Key, $Value = $_.split(':')
	$AppSettingsHash[$Key] = $Value
}

#Create array of app setting names that will be slot settings
$AppSettingNamesArray = new-object string[] $AppSettingsHash.Count
$count = 0
foreach ($Key in $AppSettingsHash.Keys)
{
	$AppSettingNamesArray[$count] = $Key
	$count++
}

#Set Production or staging slot app settings based on $Slot 
if ($Slot -eq [string]::Empty)
{
	Set-AzureRmWebApp -ResourceGroupName $ResourceGroupName -Name $SiteName -AppSettings $AppSettingsHash
}
else 
{
	Set-AzureRmWebAppSlot -ResourceGroupName $ResourceGroupName -Name $SiteName -Slot $Slot -AppSettings $AppSettingsHash
	Set-AzureRmWebAppSlotConfigName -ResourceGroupName $ResourceGroupName -Name $SiteName -AppSettingNames $AppSettingNamesArray
}