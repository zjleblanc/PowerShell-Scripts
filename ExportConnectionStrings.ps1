param(
	[string] [Parameter(Mandatory=$true)] $ResourceGroupName,
	[string] [Parameter(Mandatory=$true)] $SiteName,
	[string] [Parameter(Mandatory=$false)] $Slot,
	[string] [Parameter(Mandatory=$false)] $OutFile=".\ConnectionStrings.txt"
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

if(Test-Path $OutFile)
{
	Clear-Content $OutFile
}

foreach($cs in $Site.SiteConfig.ConnectionStrings){
	"$($cs.Name),$($cs.ConnectionString),$($cs.Type)" | Out-File $OutFile -Append
}

Write-Host "Exported connection strings for $($SiteName) to $($OutFile)"