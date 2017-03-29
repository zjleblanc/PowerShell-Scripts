param(
	[string] [Parameter(Mandatory=$true)] $ResourceGroupName,
	[string] [Parameter(Mandatory=$true)] $SiteName,
	[string] [Parameter(Mandatory=$false)] $Slot,
	#Assumes comma separated key-value pairs in $InputFile
	[string] [Parameter(Mandatory=$false)] $InputFile = ".\ConnectionStrings.txt"
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

$ConnectionStringsHashTable = @{}

#Add existing connection strings to hash
foreach ($cs in $Site.SiteConfig.ConnectionStrings)
{
	$ConnectionStringsHashTable.Add($cs.Name, @{ Type=$cs.Type ; Value=$cs.ConnectionString })
}

#Get connection strings from file to import
Get-Content $InputFile | Foreach-Object {
	$Name, $Connection, $Type = $_.split(',')
	
	$connectionStringToImport = New-Object Microsoft.Azure.Management.WebSites.Models.ConnStringInfo
	$connectionStringToImport.Name = $Name
	$connectionStringToImport.ConnectionString = $Connection
	$connectionStringToImport.Type = $Type
	
	$ConnectionStringsHashTable[$Name] = @{ Type=$Type ; Value=$Connection }
}

#Create array of connection string names that will be slot settings
$ConnectionStringNamesArray = new-object string[] $ConnectionStringsHashTable.Count
$count = 0
foreach ($Key in $ConnectionStringsHashTable.Keys)
{
	$ConnectionStringNamesArray[$count] = $Key
	$count++
}


#Set Production or staging slot connection strings based on $Slot 
if ($Slot -eq [string]::Empty)
{
	Set-AzureRmWebApp -ResourceGroupName $ResourceGroupName -Name $SiteName -ConnectionStrings $ConnectionStringsHashTable
}
else 
{
	Set-AzureRmWebAppSlot -ResourceGroupName $ResourceGroupName -Name $SiteName -Slot $Slot -ConnectionStrings $ConnectionStringsHashTable
	Set-AzureRmWebAppSlotConfigName -ResourceGroupName $ResourceGroupName -Name $SiteName -ConnectionStringNames $ConnectionStringNamesArray
}
