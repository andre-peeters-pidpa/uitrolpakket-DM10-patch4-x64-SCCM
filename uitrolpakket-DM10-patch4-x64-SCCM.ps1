################################################################################
#
# NAME: uitrolpakket-DM10-patch4-x64-SCCM
#
# AUTHOR:  apadmin
#
# COMMENT: Installatie patch 4 voor DM 10
#
# VERSION HISTORY:
# 1.0 09/10/2017 - Initial release
#
################################################################################

[CmdletBinding()]param()

$DMLeveldescription = "eDocs DM 10"
$DMLeveltext = "10.0.0"
$DMLevel = 10

$patchLeveldescription = "DM 10 Patch 4"
$patchLeveltext = "1361 Patch 4"
$patchLevel = 4
$patchfiles = @(
 "DM_extensions\eDOCS DM 10 Extensions Patch 4 (x64).msi"
,"eDOCS DM 10 Extensions Patch 3 (x64).msi"
)
$extrafiles = @(
 "DMsettings-x64.reg"
)

#hotfixes
$hotfixes = @(
)
$hotfixesNL = @(
)

#dotnetversionNeeded
$dotNetVersionNeeded = 4.5

################################################################################
# NO EDITING IS NEEDED BELOW THIS LINE                                         #
################################################################################

$base = (get-item $myInvocation.InvocationName).DirectoryName
$scriptName = $myInvocation.MyCommand.Name 
$scriptPath = $myInvocation.MyCommand.Path

$env:PSModulePath = @($env:PSModulePath , "\\pidpant\filesystem\SoftDist\PowerShellModules\" , (get-item $myInvocation.InvocationName).DirectoryName ) -join ';'
Import-Module -Name writelog   -ErrorAction SilentlyContinue
writelog -message "start $scriptName"
$Error.Clear()

Import-Module -Name installMSI -ErrorAction SilentlyContinue
if ( $Error ) {
    writelog -entrytype Error -terminate -message "installMSI is needed, but not found"
}

#set a logfile
writelog -logfile installatieDM10-patch4.log -message "start script"

#test for administrator access
function Test-Administrator {
	$user = [Security.Principal.WindowsIdentity]::GetCurrent() 
	( New-Object Security.Principal.WindowsPrincipal $user ).IsInRole( [Security.Principal.WindowsBuiltinRole]::Administrator )
}
if ( -not (Test-Administrator) ) {
	writelog -entrytype error -message "You need to be Administrator" -terminate
}

if ( ( [int](Get-WmiObject win32_OperatingSystem).OSArchitecture.substring(0,2) ) -ne 64) {
    writelog -terminate -entrytype Error -message "Only on 64 os"
}

#voor debugging only, remove next line in production
$VerbosePreference = 'continue'

$OperatingSystem = (Get-WmiObject win32_OperatingSystem).Caption
$OSArchitecture = [int](Get-WmiObject win32_OperatingSystem).OSArchitecture.substring(0,2)


#check for dot net 4.5
if ( (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name "Version").Version.substring(0,3) -lt $dotNetVersionNeeded) 
{
	writelog -terminate -message "4.5 NOT installed, aborting installation"
}
writelog -message ".net 4.5 installed"

#$msparguments = 'REINSTALLMODE="oms" REINSTALL="ALL" '
$msparguments = ''
$msparguments += '/l*v "C:\Temp\DM10InstallPatch{0}.log"' -f $patchLevel


#rem installatie DM 10
#Open Text eDOCS DM 10 Extensions (x64)
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

#stop if dm is less than
if ($vlevel -lt $DMLevel ) 
{
	# dm 10 not installed, so we install
	"patches only for {0}" -f $DMLeveldescription | writelog -entrytype Error -terminate 
}
if  ($plevel -ge $patchlevel) {
    "patchlevel {} is already {} or higher" -f $patchLevel, $patchLeveldescription | writelog -entrytype Information -terminate
}

#install the patches

foreach ($patchfile in $patchfiles) {
	"install {0}" -f $patchfile |  writelog 
	$returncode = installMSI -file (join-path $base $patchfile) -arg $msparguments -abortOnError
	if ( $returncode -eq 3010 )
	{
		$rebootneeded = $true
        writelog -message "reboot is neccesary"
	}
    writelog -message "MSIexec returned following code $returncode"
}

#install hotfixes
$installpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Hummingbird\DM Extensions' -Name "InstallPath")."Installpath"
foreach ($hotfix in $hotfixes) {
	$hotfixSource = join-path $base $hotfix
	if ( ( test-path $hotfixSource ) -and ( (get-childitem $hotfixSource).LastWriteTime -gt (get-childitme (join-path $installpath $hotfixe)).LastWriteTime ) )
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
	$hotfixSource = join-path $base $hotfix
	if ( ( test-path $hotfixSource ) -and ( (get-childitem $hotfixSource).LastWriteTime -gt (get-childitme (join-path $installpath $hotfixe)).LastWriteTime ) )
	{
		try {
			Copy-Item -Path $hotfixSource -Destination $installpath -Force 
			writelog -message "$hotfixSource is gekopieerd naar $installpath"
		} catch {
			writelog -entrytype error -message $Error
		}
	}
}

# extrafiles
$installpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Hummingbird\DM Extensions' -Name "InstallPath")."Installpath"
foreach ($extrafile in $extrafiles) {
	$extrafileSource = join-path $base $extrafile
	if ( ( test-path $extrafileSource ) -and ( (get-childitem $extrafileSource).LastWriteTime -gt (get-childitme (join-path $installpath $extrafile)).LastWriteTime ) )
	{
		try {
			Copy-Item -Path $extrafileSource -Destination $installpath -Force 
			writelog -message "$extrafileSource is gekopieerd naar $installpath"
		} catch {
			writelog -entrytype error -message $Error
		}
	}
}

#add pidpa specific regkeys
$installpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Hummingbird\DM Extensions' -Name "InstallPath")."Installpath"

writelog -message "copy $regFileSource to $regfile"
writelog -message "import registry"
$returncode = Invoke-Command -ScriptBlock { cmd /c regedit /S $regfile }
$returncode | foreach-object { writelog -message $_ }


writelog -message "end $scriptName"
if ( $rebootneeded )
{
	Write-Warning "-----------------------------------------"
	Write-Warning "| Please Reboot to finish installation! |"
	Write-Warning "-----------------------------------------"
}

return $returncode