################################################################################
#
# NAME: uitrolpakket-p1-DM10-for-2013-x64
#
# AUTHOR:  apadmin
#
# COMMENT: Installatie DM 10 / upgrade naar DM 10
#
# VERSION HISTORY:
# 1.0 26/02/2016 - Initial release
# 2.0 19/04/2016 - adapted for dm 10
# 3.0 08/08/2016 - adapted for office 2013
# 3.1 26/05/2017 - added patch for NL submap
# 3.2 29/05/2016 - universele paden naar modules
#
################################################################################

[CmdletBinding()]param()

#base location of installsoftware
#$base=(Resolve-Path .\).Path + "\"
$base = (get-item $myInvocation.InvocationName).DirectoryName

$env:PSModulePath = @($env:PSModulePath , "\\pidpant\filesystem\SoftDist\PowerShellModules\" , (get-item $myInvocation.InvocationName).DirectoryName ) -join ';'
Import-Module -Name writelog   -ErrorAction SilentlyContinue
$Error.Clear()
Import-Module -Name installMSI -ErrorAction SilentlyContinue
if ( $Error ) {
    throw "installMSI is needed, but not found"
}

#set a logfile
writelog -logfile installatieDM10-2013.log -message "start script"

#test for administrator access
function Test-Administrator {
	$user = [Security.Principal.WindowsIdentity]::GetCurrent() 
	( New-Object Security.Principal.WindowsPrincipal $user ).IsInRole( [Security.Principal.WindowsBuiltinRole]::Administrator )
}
if ( -not (Test-Administrator) ) {
	writelog -entrytype error -message "You need to be Administrator" -terminate
}

#voor debugging only, remove next line in production
#$VerbosePreference = 'continue'

$OperatingSystem = (Get-WmiObject win32_OperatingSystem).Caption
$OSArchitecture = [int](Get-WmiObject win32_OperatingSystem).OSArchitecture.substring(0,2)
$scriptName = $myInvocation.MyCommand.Name 
$scriptPath = $myInvocation.MyCommand.Path

writelog -message "start $scriptName"

#check for dot net 4.5
if ( (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name "Version").Version.substring(0,3) -lt '4.5') 
{
	writelog -terminate -message "4.5 NOT installed, aborting installation"
}
writelog -message ".net 4.5 installed"

# is office 15 (2013) installed

if ( (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90150000-002A-0000-1000-0000000FF1CE}' -Name "DisplayVersion").DisplayVersion.split('.')[0] -ne '15') 
{
	writelog -terminate -message "Office 2013 is not installed"
}
writelog -message "Office 2013 is installed"

$officeInstallpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90150000-002A-0000-1000-0000000FF1CE}' -Name "InstallLocation").InstallLocation
$officeInstallpath += "Office" + (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90150000-002A-0000-1000-0000000FF1CE}' -Name "DisplayVersion").DisplayVersion.split('.')[0]
$officeInstallpath += "\"
$officeInstallpath = get-item $officeInstallpath
$officeapps = @{"Word"="winword.exe";"Excel"="excel.exe";"Outlook"="outlook.exe";"PPT"="powerpnt.exe";"Visio"="visio.exe"}
$officeapps.Keys | ForEach-Object { if ( (Get-ChildItem $officeInstallpath ) -imatch $officeapps[$_] ) { 
    $m = "installing integration for {0} ({1})" -f $_, $officeapps[$_]
    writelog -message $m
} }

#base location of installsoftware
#$base = "\\pidpant\filesystem\SoftDist\DM\1000\"
$msifile = $base + "DM_extensions\eDOCS DM 10 Extensions (x64).msi"

#installation arguments
$msiarguments = 'ADDLOCAL="DMExtensionsAPIFeature,ExplorerNamespace,DynamicViewsFeature,'
if ( (Get-ChildItem $officeInstallpath ) -imatch "winword.exe" ) { 
    $msiarguments += 'Microsoft.Word.Features,Microsoft.Word.2013.x86,'
}
if ( (Get-ChildItem $officeInstallpath ) -imatch "excel.exe" ) { 
    $msiarguments += 'Microsoft.Excel.Features,Microsoft.Excel.2013.x86,'
}
if ( (Get-ChildItem $officeInstallpath ) -imatch "powerpnt.exe" ) { 
    $msiarguments += 'Microsoft.PPT.Features,Microsoft.PPT.2013.x86,'
}
if ( (Get-ChildItem $officeInstallpath ) -imatch "visio.exe" ) { 
    $msiarguments += 'Microsoft.Visio.Features.Microsoft.Visio.2013.x86,'
}
$msiarguments += 'LinkingFeatures,'
$msiarguments += 'Linking.Other,'
if ( (Get-ChildItem $officeInstallpath ) -imatch "winword.exe" ) { 
    $msiarguments += 'Linking.Word.Features,Linking.Word.2013.x86,'
    }
if ( (Get-ChildItem $officeInstallpath ) -imatch "excel.exe" ) { 
    $msiarguments += 'Linking.Excel.Features,Linking.Excel.2013.x86,'
    }
if ( (Get-ChildItem $officeInstallpath ) -imatch "powerpnt.exe" ) { 
    $msiarguments += 'Linking.PPT.Features,Linking.PPT.2013.x86,'
    }
if ( (Get-ChildItem $officeInstallpath ) -imatch "outlook.exe" ) { 
    $msiarguments += 'Microsoft.Outlook.Features,Microsoft.Outlook.2013.x86,'
    }
$msiarguments += 'DMViewer,CheckinCheckoutFeature,CDU" '
$msiarguments += 'REMOVE="Interceptor" '
$msiarguments += 'OFFICE_INTEGRATION_TYPE="Automation" '
if ( (Get-ChildItem $officeInstallpath ) -imatch "winword.exe" ) { 
    $msiarguments += 'WORD_INTEGRATION_LEVEL="Active" '
    }
if ( (Get-ChildItem $officeInstallpath ) -imatch "excel.exe" ) { 
    $msiarguments += 'EXCEL_INTEGRATION_LEVEL="Active" '
    }
if ( (Get-ChildItem $officeInstallpath ) -imatch "powerpnt.exe" ) { 
    $msiarguments += 'POWERPOINT_INTEGRATION_LEVEL="Active" '
    }
if ( (Get-ChildItem $officeInstallpath ) -imatch "visio.exe" ) { 
    $msiarguments += 'VISIO_INTEGRATION_LEVEL="Active" '
    }
$msiarguments += 'DMSERVERNAME=DM '
$msiarguments += '/l*v "C:\Temp\DM10InstallBase.log"'

$patchLevel = "792 Patch 2"
$patchLevel = 2
$mspfile = $base + "DM_extensions\eDOCS DM 10 Extensions (x64) Patch 2.msp"
#$msparguments = 'REINSTALLMODE="oms" REINSTALL="ALL" '
$msparguments = ''
$msparguments += '/l*v "C:\Temp\DM10InstallPatch2.log"'

$regfileSource = $base + "DMsettings-x64.reg"

#hotfixes
$hotfixes = @(
"dm.ini"
,"DM_extensions\DM-36665\DMForms.dll"
,"DM_extensions\DM-36665\SaveUIApp.dll"
,"DM_extensions\DM-36665\SaveUIUtility.dll"
,"DM_extensions\DM-36749\FsPlugin.dll"
,"DM_extensions\DM-35882\WCFRes.dll"
)

$hotfixesNL = @(
 "DM_extensions\DM-35882\WCFRes.dll"
)

#remove DM 
#oude versie wordt gewist door de installatie van de nieuwe versie

#rem installatie DM 10
#Open Text eDOCS DM 10 Extensions (x64)
try {
	$vlevel = [int]((Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Hummingbird\Installed Version' -name "DM Extensions")."DM Extensions").split(".")[0]
}catch{
	$vlevel = 0
}
if ($vlevel -lt 10 ) 
{
	# dm 10 not installed, so we install
	writelog -message "install DM 10 base"
	
# 2017-04-18 kill msiexec because process doesn't return at all
#	Get-Process -Name msiexec | Stop-Process -Force

	$returncode = installMSI -file $msifile -arg $msiarguments -abortOnError

	Write-Host "returncode = " $returncode

	if ( $returncode -eq 3010 )
	{
		$rebootneeded = $true
        writelog -message "reboot is neccesary"
	} 
    writelog -message "MSI returned following code $returncode"
}
else
{
	writelog -message "Open Text DM 10 is already installed"
}

#check for installed version and patch level
try {
	$vlevel = [int]((Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Hummingbird\Installed Version' -name "DM Extensions")."DM Extensions").split(".")[0]
}catch{
	$vlevel = 0
}
try {
	$plevel = [int](Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Hummingbird\Hummingbird DM API' -Name "PatchLevel").patchlevel.split()[-1]
} catch {
	$plevel = 0
}
if ( ($vlevel -eq 10 ) -and ($plevel -lt $patchlevel) )
{
	#install patchlevel 2
	writelog -message "install DM 10 patch 2"
	$returncode = installMSP -file $mspfile -arg $msparguments -abortOnError
	if ( $returncode -eq 3010 )
	{
		$rebootneeded = $true
        writelog -message "reboot is neccesary"
	}
    writelog -message "MSP returned following code $returncode"
}
else
{
	writelog -message "patch 2 or higher is installed"
}

#install hotfixes
try {
	$plevel = [int](Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Hummingbird\Hummingbird DM API' -Name "PatchLevel").patchlevel.split()[-1]
} catch {
	$plevel = 0
}
if ( $vlevel -eq 10 ) {
	$installpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Hummingbird\DM Extensions' -Name "InstallPath")."Installpath"
	foreach ($hotfix in $hotfixes) {
		$hotfixSource = $base + $hotfix
		if ( test-path $hotfixSource )
		{
			try {
				Copy-Item -Path $hotfixSource -Destination $installpath -Force 
				writelog -message "$hotfixSource has been copied"
			} catch {
				writelog -entrytype error -message $Error
			}
		}
	}
    # hotfixes voor de NL map
	$installpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Hummingbird\DM Extensions' -Name "InstallPath")."Installpath"
    $installpath = Join-Path $installpath "nl"
	foreach ($hotfix in $hotfixesNL) {
		$hotfixSource = $base + $hotfix
		if ( test-path $hotfixSource )
		{
			try {
				Copy-Item -Path $hotfixSource -Destination $installpath -Force 
				writelog -message "$hotfixSource is gekopieerd naar $installpath"
			} catch {
				writelog -entrytype error -message $Error
			}
		}
	}
}

#add pidpa specific regkeys
try {
	$plevel = [int](Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Hummingbird\Hummingbird DM API' -Name "PatchLevel").patchlevel.split()[-1]
} catch {
	$plevel = 0
}
if ( $vlevel -eq 10 ) {
	$installpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Hummingbird\DM Extensions' -Name "InstallPath")."Installpath"
	$regfile = $installpath + "DMsettings-x64.reg"

	if ( test-path $regfileSource )
	{
	    if ( Test-Path $regfile ) 
	    {
	        if ( (Get-Item $regfileSource).LastWriteTime -gt (Get-Item $regfile).LastWriteTime ) 
	        {
	            $Error.Clear()
	            Remove-Item -LiteralPath $regfile -Force
	            if (-not $error)
	            {
	                writelog -message "$regfile is removed"
	            }
	            else
	            {
	                writelog -entrytype error -message "$regfile could not be removed"
	            }
	        }
	        else
	        {
	            writelog -message "$regfile is ok"
	        }
	    }
	    if ( (Test-Path $regfile) -eq $false ) 
	    {
	    	writelog -message "copy $regFileSource to $regfile"
	        $Error.clear()
	        Copy-Item -LiteralPath $regfileSource -Destination $regfile -Force
	        if ( -not $error) 
	        {
	        	writelog -message "import registry"
	        	$returncode = Invoke-Command -ScriptBlock { cmd /c regedit /S $regfile }
	        	$returncode | foreach-object { writelog -message $_ }
	        }
	        else
	        {
	            writelog -entrytype error -message "$regfile could not be copied"
	        }
	    }
	}
	else
	{
		writelog -entrytype Error -message "source files and or \\pidpant\filesystem\softdist not available, aborting install" -terminate
	}
}

writelog -message "end $scriptName"
if ( $rebootneeded )
{
	Write-Warning "-----------------------------------------"
	Write-Warning "| Please Reboot to finish installation! |"
	Write-Warning "-----------------------------------------"
}

return $returncode