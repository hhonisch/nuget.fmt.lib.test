#Requires -Version 5

param(
    # Install VS build tools
    [Parameter(Mandatory = $true, ParameterSetName = "InstallVSBuildTools")]
    [switch] $InstallVsBuildTools,
    # Build release info
    [Parameter(Mandatory = $true, ParameterSetName = "BuildReleaseInfo")]
    [switch] $BuildReleaseInfo,
    # Build release notes
    [Parameter(Mandatory = $true, ParameterSetName = "BuildReleaseNotes")]
    [switch] $BuildReleaseNotes,
    # VS build tools version
    [Parameter(Mandatory = $true, ParameterSetName = "InstallVSBuildTools")]
    [ValidateSet("14.0", "14.1", "14.2", "14.3")]
    [string] $Version,
    # GitHub properties file
    [Parameter(Mandatory = $true, ParameterSetName = "BuildReleaseInfo")]
    [string] $GitHubPropsFile,
    # Release info file
    [Parameter(Mandatory = $true, ParameterSetName = "BuildReleaseInfo")]
    [string] $ReleaseInfoFile,
    # Nuget package version
    [Parameter(Mandatory = $true, ParameterSetName = "BuildReleaseInfo")]
    [Parameter(ParameterSetName = "BuildReleaseNotes")]
    [string] $PackageVersion,
    # Fmt version
    [Parameter(Mandatory = $true, ParameterSetName = "BuildReleaseInfo")]
    [Parameter(ParameterSetName = "BuildReleaseNotes")]
    [string] $FmtVersion,
    # Fmt download URL
    [Parameter(Mandatory = $true, ParameterSetName = "BuildReleaseInfo")]
    [string] $FmtDownloadUrl,
    # Fmt download ZIP filename
    [Parameter(Mandatory = $true, ParameterSetName = "BuildReleaseInfo")]
    [string] $FmtDownloadZip,
    # Release notes template
    [Parameter(Mandatory = $true, ParameterSetName = "BuildReleaseNotes")]
    [string] $ReleaseNotesTemplate,
    # Release notes output
    [Parameter(Mandatory = $true, ParameterSetName = "BuildReleaseNotes")]
    [string] $ReleaseNotesOutput
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


# Build release info
function BuildReleaseInfo($gitHubPropsFile, $releaseInfoFile, $packageVersion, $fmtVersion, $fmtDownloadUrl, $fmtDownloadZip) {

    # Get commit hash
    $commitHash = $env:GITHUB_SHA

    # Get run ID
    $runId = $env:GITHUB_RUN_ID

    # Build release info
    $json = [ordered]@{
        "package-version"    = $packageVersion
        "fmt-version"        = $fmtVersion
        "fmt-download-url"   = $fmtDownloadUrl
        "fmt-download-zip"   = Split-Path -Leaf $fmtDownloadZip
        "github-run-id"      = $runId
        "github-commit-hash" = $commitHash
    }
    $jsonStr = ConvertTo-Json $json -Compress

    # Write release info
    Write-Host "  Release info: $jsonStr"
    Write-Host "  Appending release info to $gitHubPropsFile"
    "release-info=$jsonStr" | Out-File $gitHubPropsFile -Append -Encoding ascii
    Write-Host "  Writing release info to $releaseInfoFile"
    $jsonStr | Out-File $releaseInfoFile -Encoding ascii
}


# Build rekease notes
function BuildReleaseNotes($templatePath, $outputPath, $packageVersion, $fmtVersion) {
    Write-Host "  Reading release notes template from $templatePath"
    $releaseNotes = Get-Content $templatePath

    Write-Host "  Replacing placeholders..."
    $releaseNotes = $releaseNotes -creplace "%FMT_VERSION%", $fmtVersion
    $releaseNotes = $releaseNotes -creplace "%PACKAGE_VERSION%", $packageVersion

    Write-Host "  Writing release notes to $templatePath"
    $releaseNotes | Out-File -FilePath $outputPath -Encoding utf8
}

# Main function
function Main {
    # Handle installing VS build tools
    if ($InstallVsBuildTools) {
        InstallVsBuildTools $Version
    }

    # Build release info
    if ($BuildReleaseInfo) {
        BuildReleaseInfo $GitHubPropsFile $ReleaseInfoFile $PackageVersion $FmtVersion $FmtDownloadUrl $FmtDownloadZip
    }

    # Build release notes
    if ($BuildReleaseNotes) {
        BuildReleaseNotes $ReleaseNotesTemplate $ReleaseNotesOutput $PackageVersion $FmtVersion
    }
}


Main
