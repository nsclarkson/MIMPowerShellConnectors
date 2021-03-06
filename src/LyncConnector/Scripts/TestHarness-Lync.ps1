<#
<copyright file="TestHarness-Lync.ps1" company="Microsoft">
	Copyright (c) Microsoft. All Rights Reserved.
	Licensed under the MIT license. See LICENSE.txt file in the project root for full license information.
</copyright>
<summary>
	The TestHarness script for the Skype 2015 / Lync 2013 / Lync 2010 Connector.
	Modify the script / MA Configuration section as per your development enviorment.
</summary>
#>

Set-StrictMode -Version "2.0"

$Global:DebugPreference = "Continue"
$Global:VerbosePreference = "Continue"

$scriptDir = $PWD
$commonModuleName = "1. Lync.Common"
$testHarnessModuleName = "TestHarness.Common"

#region "Load Modules and Types"

function Load-Module
{
	[CmdletBinding()]
	param(
		[parameter(Mandatory = $true)]
		[string]
		$ModuleName
	)

	$modulePath = Join-Path -Path $scriptDir -ChildPath ($ModuleName + ".psm1")

	if (!(Get-Module -Name $ModuleName))
	{
		if (!(Test-Path $modulePath))
		{
			throw ("{0} module could not be located." -f $modulePath)
		}
	}
	else
	{
		Remove-Module -Name $ModuleName
	}

	Import-Module -Name $modulePath
}

Load-Module -ModuleName $commonModuleName
Load-Module -ModuleName $testHarnessModuleName

$extensionsDir = Get-ExtensionsDirectory

if ($PWD -ne $extensionsDir)
{
	$metadirectoryServicesEx = Join-Path -Path (Split-Path -Path $extensionsDir -Parent) -ChildPath "Bin\Assemblies\Microsoft.MetadirectoryServicesEx.dll"
}
else
{
	$metadirectoryServicesEx = Join-Path -Path $scriptDir -ChildPath "..\..\ReferencedAssemblies\Microsoft.MetadirectoryServicesEx.dll"
}

if (!(Test-Path $metadirectoryServicesEx))
{
	throw ("{0} could not be located." -f $metadirectoryServicesEx)
}

Add-Type -Path $metadirectoryServicesEx

#endregion "Load Modules and Types"

#region "MA Configuration"

function Get-ConfigParameterKeyedCollection
{
	$configParameters = New-Object Microsoft.MetadirectoryServices.ConfigParameterKeyedCollection

	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Server", "https://s4badmin.contoso.com/OcsPowerShell")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Domain", "CONTOSO")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("User", "svc_fim_s4bma")))
	$password = ConvertTo-SecureString -AsPlainText "Pass@word1" -Force
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Password", $password)))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Impersonate Connector Account", "0")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Load User Profile When Impersonating", "0")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Logon Type When Impersonating", "0")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Signed Scripts Only", "0")))

	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Common Module Script Name (with extension)", ($commonModuleName + ".psm1"))))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Validation Script", "2. ValidationScript-Lync.ps1")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Schema Script", "3. SchemaScript-Lync.ps1")))

	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Partition Script", "4. PartitionScript-Lync.ps1")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Hierarchy Script", "5. HierarchyScript-Lync.ps1")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Begin Import Script", "6. Begin-ImportScript-Lync.ps1")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Import Script", "7. ImportScript-Lync.ps1")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("End Import Script", "8. End-ImportScript-Lync.ps1")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Begin Export Script", "9. Begin-ExportScript-Lync.ps1")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Export Script", "10. ExportScript-Lync.ps1")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("End Export Script", "11. End-ExportScript-Lync.ps1")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Begin Password Script", "")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Password Extension Script", "")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("End Password Script", "")))

	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("SipAddressType_Global", "UserPrincipalName")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("SipDomain_Global", "")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("ForceMove_Global", "Yes")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("UserPages_Global", "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,0,1,2,3,4,5,6,7,8,9")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("OrganizationalUnitPages_Global", "")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("PreferredDomainControllerFQDN_Global", "")))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("LastRunDateTimeOffsetMinutes_Global", "30")))
	
	# Test Harness Test data
	$exportDropFile = Join-Path -Path $scriptDir -Childpath "..\TestData\Lync-Export-Add-User.xml"
	##$exportDropFile = Join-Path -Path $scriptDir -Childpath "..\TestData\Lync-Export-Update-User.xml"
	##$exportDropFile = Join-Path -Path $scriptDir -Childpath "..\TestData\Lync-Export-Delete-User.xml"
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Export Simulation Data File", $exportDropFile)))
	$configParameters.Add((New-Object Microsoft.MetadirectoryServices.ConfigParameter("Import Dump Data File", "..\TestData\Lync-Import-Dump.xml")))

	$Script:PartitionDN = "DC=Contoso,DC=Com"

	return ,$configParameters
}

#endregion "MA Configuration"


function Get-Schema
{
	$script = Join-Path -Path $scriptDir -ChildPath $configParameters["Schema Script"].Value

	Write-Debug ("Starting executing Schema script {0}..." -f $script)

	$results = & $script $configParameters $psCredential $scriptDir

	Write-Debug ("Completed executing Schema script {0}." -f $script)

	foreach ($obj in $results)
	{
		if ($obj.GetType().FullName -eq "Microsoft.MetadirectoryServices.Schema")
		{
			$schema = $obj
			break;
		}
		else
		{
			Write-Error ("Unexpected return type {0} from Schema script." -f $obj.GetType().FullName)
		}
	}

	return $schema
}

function Get-Partitions
{
	$script = Join-Path -Path $scriptDir -ChildPath $configParameters["Partition Script"].Value

	Write-Debug ("Starting executing Partition script {0}..." -f $script)

	$results = & $script $configParameters $psCredential $scriptDir

	Write-Debug ("Completed executing Partition script {0}." -f $script)

	$partitions = New-GenericObject System.Collections.Generic.List Microsoft.MetadirectoryServices.Partition

	foreach ($obj in $results)
	{
		if ($obj.GetType().FullName -eq "Microsoft.MetadirectoryServices.Partition")
		{
			$partitions.Add($obj)
			Write-Debug ("Partition: {0}" -f $obj.Name)
		}
		else
		{
			Write-Error ("Unexpected return type {0} from Partition script." -f $obj.GetType().FullName)
		}
	}

	return $partitions
}

function Get-Hierarchy
{
	$script = Join-Path -Path $scriptDir -ChildPath $configParameters["Hierarchy Script"].Value

	$dn = $Script:PartitionDN
	$name = $Script:PartitionDN
	$hierarchyNode = [Microsoft.MetadirectoryServices.HierarchyNode]::Create($dn, $name)

	Write-Debug ("Starting executing Hierarchy script {0}..." -f $script)

	$results = & $script $hierarchyNode $configParameters $psCredential $scriptDir

	Write-Debug ("Completed executing Hierarchy script {0}." -f $script)

	$children = New-GenericObject System.Collections.Generic.List Microsoft.MetadirectoryServices.HierarchyNode

	foreach ($obj in $results)
	{
		if ($obj.GetType().FullName -eq "Microsoft.MetadirectoryServices.HierarchyNode")
		{
			$children.Add($obj)
			Write-Debug ("HierarchyNode: {0}" -f $obj.DisplayName)
		}
		else
		{
			Write-Error ("Unexpected return type {0} from HierarchyNode script." -f $obj.GetType().FullName)
		}
	}

	return $children
}

function Get-OpenImportConnectionRunStep
{
	$dn = $Script:PartitionDN
	$name = $Script:PartitionDN
	$partition = [Microsoft.MetadirectoryServices.Partition]::Create([Guid]::Empty, $dn, $name)
	$importType = "Full" # or "Delta"
	$pageSize = 10
	
	$currentPageIndex = 0
	$userMoreToImport = 1
	$ouMoreToImport = 1
	$preferredDomainController = $configParameters["PreferredDomainControllerFQDN_Global"].Value
	$lastRunDateTime = $null

	$customData = "<WaterMark>"
	$customData += "<CurrentPageIndex>{0}</CurrentPageIndex>" -f $currentPageIndex
	$customData += "<User><MoreToImport>{0}</MoreToImport></User>" -f $userMoreToImport
	$customData += "<OrganizationalUnit><MoreToImport>{0}</MoreToImport></OrganizationalUnit>" -f $ouMoreToImport
	$customData += "<PreferredDomainController>{0}</PreferredDomainController>" -f $preferredDomainController
	$customData += "<LastRunDateTime>{0}</LastRunDateTime>" -f $lastRunDateTime
	$customData += "</WaterMark>"
	
	$inclusionHierarchyNodes = New-GenericObject System.Collections.Generic.List Microsoft.MetadirectoryServices.HierarchyNode
	$exclusionHierarchyNodes = New-GenericObject System.Collections.Generic.List Microsoft.MetadirectoryServices.HierarchyNode

	$dn = $Script:PartitionDN
	$name = $Script:PartitionDN
	$inclusionHierarchyNode = [Microsoft.MetadirectoryServices.HierarchyNode]::Create($dn, $name)
	$inclusionHierarchyNodes.Add($inclusionHierarchyNode) 

	$openImportConnectionRunStep = New-Object Microsoft.MetadirectoryServices.OpenImportConnectionRunStep($partition, $importType, $pageSize, $customData, $inclusionHierarchyNodes, $exclusionHierarchyNodes)

	return $openImportConnectionRunStep 
}

function Get-ImportEntriesRunStep
{
	$currentPageIndex = 0
	$userMoreToImport = 1
	$ouMoreToImport = 1
	$preferredDomainController = $configParameters["PreferredDomainControllerFQDN_Global"].Value
	$lastRunDateTime = $null

	$customData = "<WaterMark>"
	$customData += "<CurrentPageIndex>{0}</CurrentPageIndex>" -f $currentPageIndex
	$customData += "<User><MoreToImport>{0}</MoreToImport></User>" -f $userMoreToImport
	$customData += "<OrganizationalUnit><MoreToImport>{0}</MoreToImport></OrganizationalUnit>" -f $ouMoreToImport
	$customData += "<PreferredDomainController>{0}</PreferredDomainController>" -f $preferredDomainController
	$customData += "<LastRunDateTime>{0}</LastRunDateTime>" -f $lastRunDateTime
	$customData += "</WaterMark>"

	$fullObjectEntries = $null
	$getImportEntriesRunStep = New-Object Microsoft.MetadirectoryServices.GetImportEntriesRunStep($fullObjectEntries, $customData)

	return $getImportEntriesRunStep
}

function Get-CloseImportConnectionRunStep
{
	$currentPageIndex = 0
	$userMoreToImport = 1
	$ouMoreToImport = 1
	$preferredDomainController = $configParameters["PreferredDomainControllerFQDN_Global"].Value
	$lastRunDateTime = $null

	$customData = "<WaterMark>"
	$customData += "<CurrentPageIndex>{0}</CurrentPageIndex>" -f $currentPageIndex
	$customData += "<User><MoreToImport>{0}</MoreToImport></User>" -f $userMoreToImport
	$customData += "<OrganizationalUnit><MoreToImport>{0}</MoreToImport></OrganizationalUnit>" -f $ouMoreToImport
	$customData += "<PreferredDomainController>{0}</PreferredDomainController>" -f $preferredDomainController
	$customData += "<LastRunDateTime>{0}</LastRunDateTime>" -f $lastRunDateTime
	$customData += "</WaterMark>"

	$closeReason = "Normal" # or "TerminatedByUser" or "TerminatedShuttingDown"

	$closeImportConnectionRunStep = New-Object Microsoft.MetadirectoryServices.CloseImportConnectionRunStep($closeReason, $customData)

	return $closeImportConnectionRunStep 
}

function Get-OpenExportConnectionRunStep
{
	$dn = $Script:PartitionDN
	$name = $Script:PartitionDN
	$partition = [Microsoft.MetadirectoryServices.Partition]::Create([Guid]::Empty, $dn, $name)
	$exportType = "Full" # or "Delta" or "FullObject"
	$batchSize = 100
	$inclusionHierarchyNodes = New-GenericObject System.Collections.Generic.List Microsoft.MetadirectoryServices.HierarchyNode
	$exclusionHierarchyNodes = New-GenericObject System.Collections.Generic.List Microsoft.MetadirectoryServices.HierarchyNode    

	$openExportConnectionRunStep = New-Object Microsoft.MetadirectoryServices.OpenExportConnectionRunStep($partition, $batchSize, $exportType, $inclusionHierarchyNodes, $exclusionHierarchyNodes)

	return $openExportConnectionRunStep
}

function Get-CloseExportConnectionRunStep
{
	$closeReason = "Normal" # or "TerminatedByUser" or "TerminatedShuttingDown"

	$closeExportConnectionRunStep = New-Object Microsoft.MetadirectoryServices.CloseExportConnectionRunStep($closeReason)

	return $closeExportConnectionRunStep 
}

function Begin-Import
{
	$script = Join-Path -Path $scriptDir -ChildPath $configParameters["Begin Import Script"].Value

	Write-Debug ("Starting executing Begin-Import script {0}..." -f $script)

	$results = & $script $configParameters $schema $openImportConnectionRunStep $psCredential $scriptDir

	Write-Debug ("Completed executing Begin-Import script {0}." -f $script)

	foreach ($obj in $results)
	{
		if ($obj.GetType().FullName -eq "Microsoft.MetadirectoryServices.OpenImportConnectionResults")
		{
			$openImportConnectionResults = $obj
			Write-Debug ("OpenImportConnectionResults CustomData: {0}" -f $openImportConnectionResults.CustomData)
		}
		else
		{
			Write-Error ("Unexpected return type {0} from Begin-Import script." -f $obj.GetType().FullName)
		}
	}

	Write-Debug $openImportConnectionResults

	return $openImportConnectionResults
}

function Do-Import
{
	$script =  Join-Path -Path $scriptDir -ChildPath $configParameters["Import Script"].Value

	Write-Debug ("Starting executing Import script {0}..." -f $script)

	$results = & $script $configParameters $schema $openImportConnectionRunStep $getImportEntriesRunStep $psCredential $scriptDir

	Write-Debug ("Completed executing Import script {0}." -f $script)

	foreach ($obj in $results)
	{
		if ($obj.GetType().FullName -eq "Microsoft.MetadirectoryServices.GetImportEntriesResults")
		{
			$getImportEntriesResults = $obj
			Write-Debug ("GetImportEntriesResults MoreToImport: {0}" -f $getImportEntriesResults.MoreToImport)
		}
		else
		{
			Write-Error ("Unexpected return type {0} from Import script." -f $obj.GetType().FullName)
		}
	}

	if ($dumpImport)
	{
		$fileName = Join-Path -Path $scriptDir -ChildPath $configParameters["Import Dump Data File"].Value
		$schema = Get-Schema
		ConvertTo-RunProfileAuditFile -GetImportEntriesResults $getImportEntriesResults -Schema $schema -AuditFileName $fileName -RunProfileStepType "full-import"
	}

	return $getImportEntriesResults
}

function End-Import
{
	$script = Join-Path -Path $scriptDir -ChildPath $configParameters["End Import Script"].Value

	Write-Debug ("Starting executing End-Import script {0}..." -f $script)

	$results = & $script $configParameters $schema $openImportConnectionRunStep $closeImportConnectionRunStep $psCredential $scriptDir

	Write-Debug ("Completed executing End-Import script {0}." -f $script)

	foreach ($obj in $results)
	{
		if ($obj.GetType().FullName -eq "Microsoft.MetadirectoryServices.CloseImportConnectionResults")
		{
			$closeImportConnectionResults = $obj
			Write-Debug ("CloseImportConnectionResults CustomData: {0}" -f $closeImportConnectionResults.CustomData)
		}
		else
		{
			Write-Error ("Unexpected return type {0} from Import script." -f $obj.GetType().FullName)
		}
	}

	Write-Debug $closeImportConnectionResults

	return $closeImportConnectionResults
}

function Begin-Export
{
	$script = Join-Path -Path $scriptDir -ChildPath $configParameters["Begin Export Script"].Value

	Write-Debug ("Starting executing Begin-Export script {0}." -f $script)

	$results = & $script $configParameters $schema $openExportConnectionRunStep $psCredential $scriptDir

	Write-Debug ("Completed executing Begin-Export script {0}." -f $script)

	if ($results -ne $null)
	{
		Write-Warning ("Unexpected output form Begin-Export script {0}" -f $script)
		Write-Warning "$results"
	}
}

function Do-Export
{
	param($csentries = $(throw "csentries parameter is required"))

	$script =  Join-Path -Path $scriptDir -ChildPath $configParameters["Export Script"].Value

	Write-Debug ("Starting executing Export script {0}..." -f $script)

	$results = & $script $configParameters $schema $openExportConnectionRunStep $csentries $psCredential $scriptDir

	Write-Debug ("Completed executing Export script {0}." -f $script)

	foreach ($obj in $results)
	{
		if ($obj.GetType().FullName -eq "Microsoft.MetadirectoryServices.PutExportEntriesResults")
		{
			$putExportEntriesResults = $obj
		}
		else
		{
			Write-Error ("Unexpected return type {0} from Export script." -f $obj.GetType().FullName)
		}
	}

	foreach ($csentryChangeResult in $putExportEntriesResults.CSEntryChangeResults)
	{
		Write-Debug ("CSEntryChangeResult: Identifier = {0}, ErrorCode = '{1}'." -f $csentryChangeResult.Identifier, $csentryChangeResult.ErrorCode)

		$anchor = ";"

		foreach ($anchorAttribute in $csentryChangeResult.AnchorAttributes)
		{
			foreach ($valueChange in $anchorAttribute.ValueChanges)
			{
				$anchor += ("{0} = {1};" -f $anchorAttribute.Name, $valueChange.Value)
			}
		}

		$anchor = $anchor.Trim(";")
		
		if (![string]::IsNullOrEmpty($anchor))
		{
			Write-Debug ("`tAnchor = '{0}'" -f $anchor)
		}
	}
}

function End-Export
{
	$script = Join-Path -Path $scriptDir -ChildPath $configParameters["End Export Script"].Value

	Write-Debug ("Starting executing End-Export script {0}..." -f $script)

	$results = & $script $configParameters $schema $openExportConnectionRunStep $closeExportConnectionRunStep $psCredential $scriptDir

	Write-Debug ("Completed executing End-Export script {0}." -f $script)

	if ($results -ne $null)
	{
		Write-Warning "$results"
	}
}

function Simulate-Import
{
	$openImportConnectionResults = Begin-Import
	$getImportEntriesResults = Do-Import
	$closeImportConnectionResults = End-Import
}

function Simulate-Export
{
	$datafile = $configParameters["Export Simulation Data File"].Value
	$schema = Get-Schema

	$csentryChanges = ConvertFrom-RunProfileAuditFile $datafile $schema

	Begin-Export
	Do-Export $csentryChanges
	End-Export
}


$configParameters = Get-ConfigParameterKeyedCollection

$domain = $configParameters["Domain"].Value
$user = $configParameters["User"].Value

if (![string]::IsNullOrEmpty($domain))
{
	$user = "$domain\$user"
}

$password = $configParameters["Password"].SecureValue

$psCredential = New-Object System.Management.Automation.PSCredential($user, $password)

$schema = Get-Schema
$partitions = Get-Partitions
$hierarchy = Get-Hierarchy
$openImportConnectionRunStep = Get-OpenImportConnectionRunStep
$getImportEntriesRunStep = Get-ImportEntriesRunStep
$closeImportConnectionRunStep = Get-CloseImportConnectionRunStep
$openExportConnectionRunStep = Get-OpenExportConnectionRunStep
$closeExportConnectionRunStep = Get-CloseExportConnectionRunStep

$dumpImport = $true
Simulate-Import
##Simulate-Export

