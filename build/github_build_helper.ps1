#Requires -Version 5

param(
    # Install VS build tools
    [Parameter(Mandatory = $true, ParameterSetName = "InstallVSBuildTools")]
    [switch] $InstallVsBuildTools,
    # VS build tools version
    [Parameter(Mandatory = $true, ParameterSetName = "InstallVSBuildTools")]
    [ValidateSet("14.0", "14.1", "14.2", "14.3")]
    [string] $Version

)


# Terminate on exception
trap {
    Write-Host "Error: $_"
    Write-Host $_.ScriptStackTrace
    exit 1
}

# Always stop on errors
$ErrorActionPreference = "Stop"

# Strict mode
Set-StrictMode -Version Latest

# Visual studio build tools data
$VSBuildTools = @{
    "14.0" = @{PackageId = "Microsoft.VisualStudio.Component.VC.140" }
    "14.1" = @{PackageId = "Microsoft.VisualStudio.Component.VC.v141.x86.x64" }
    "14.2" = @{PackageId = "Microsoft.VisualStudio.ComponentGroup.VC.Tools.142.x86.x64" }
    "14.3" = @{PackageId = "Microsoft.VisualStudio.Component.VC.Tools.x86.x64" }
}



# Install VS build tools
function InstallVsBuildTools($buildToolsVersion) {
    Write-Host "Installing Visual Studio build tools $buildToolsVersion"

    # Get info about current VS installation using vswhere
    Write-Host "  Running vswhere to get info about installed Visual Studio instances"
    [xml]$vsInfo = vswhere -latest -format xml
    $vsInstallerPath = $vsInfo.instances.instance.properties.setupEngineFilePath
    Write-Host "  Setup path: $vsInstallerPath"
    $vsInstallDir = $vsInfo.instances.instance.installationPath
    Write-Host "  Install dir: $vsInstallDir"

    # Check for installed packages
    Write-Host "  Checking for installed build tools version $buildToolsVersion"
    $setupInst = Get-VSSetupInstance -Path $vsInstallDir
    $buildToolsInstalled = $false
    $requiredPkgId = $VSBuildTools[$buildToolsVersion].PackageId
    foreach ($package in $setupInst.Packages) {
        if ( $package.Id -eq $requiredPkgId) {
            $buildToolsInstalled = $true
            break
        }
    }
    if ($buildToolsInstalled) {
        Write-Host "  VS build tools $buildToolsVersion are already installed - no action required"
        return
    }

    # Installing missing build tools
    Write-Host "  VS build tools $buildToolsVersion not found - installing..."
    $installerArgs = @("modify", "--installPath", "`"$vsInstallDir`"", "--add", "Microsoft.VisualStudio.Component.VC.140", "--downloadThenInstall", "--quiet")
    $installerArgsStr = $installerArgs -join " "
    Write-Host "  Starting VS installer: `"$vsInstallerPath`" $installerArgsStr"
    $process = Start-Process $vsInstallerPath $installerArgs -Wait -PassThru
    Write-Host "  VS installer exit code: $($process.ExitCode)"
    if ($process.ExitCode -ne 0) {
        throw "Error: Installing Visual Studio build tools version $vsInstallDir failed"
    }
    Write-Host "Done: Installing Visual Studio build tools version $vsInstallDir succeeded"
}


# Main function
function Main() {
    # Handle installing VS build tools
    if ($InstallVsBuildTools) {
        InstallVsBuildTools $Version
    }
}


Main
