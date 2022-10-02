#Requires -Version 5

param(
    # Command
    [Parameter(Mandatory)]
    [ValidateSet("StoreReleaseMetaInfo", "StoreReleaseNotes", "InstallVsBuildTools2015")]
    [string] $command
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


# Store release info in dist
function StoreReleaseMetaInfo() {
    Write-Host "Store release meta info"
    $path = Join-Path $PSScriptRoot "..\dist\meta.json"

    # Read version
    $verXmlPath = Join-Path $PSScriptRoot version.xml
    Write-Host "Reading version from $verXmlPath..."
    [xml] $verXml = Get-Content $verXmlPath
    $verStr = $verXml.version

    # Get commit hash
    $commitHash = $env:GITHUB_SHA

    # Get run ID
    $runId = $env:GITHUB_RUN_ID

    # Write JSON to file
    Write-Host "Writing to $path..."
    $json = [ordered]@{ version = $verStr; commitHash = $commitHash; githubRunId = $runId }
    ConvertTo-Json $json -Compress | Out-File $path -Encoding ascii

    Write-Host "Done: Store release meta info"
}


# Store release notes in dist
function StoreReleaseNotes() {
    Write-Host "Store release notes"

    $srcPath = Join-Path $PSScriptRoot "..\RELEASE_NOTES.md"
    $dstPath = Join-Path $PSScriptRoot "..\dist\RELEASE_NOTES.md"
    Write-Host "Reading from $srcPath..."
    Write-Host "Writing to $dstPath..."
    [System.IO.StreamReader] $srcReader = $null
    [System.IO.StreamWriter]  $dstWriter = $null
    try {
        $srcReader = [System.IO.StreamReader]::new($srcPath)
        $dstWriter = [System.IO.StreamWriter]::new($dstPath)
        while ($srcReader.EndOfStream -eq $false) {
            $line = $srcReader.ReadLine()
            if ($line -match "^\s*--- End of Release Notes ---\s*$") {
                break
            }
            $dstWriter.WriteLine($line)
        }

    }
    finally {
        if ($srcReader) {
            $srcReader.Close()
        }
        if ($dstWriter) {
            $dstWriter.Close()
        }
    }

    Write-Host "Done: Store release notes"
}


# Store release notes in dist
function InstallVsBuildTools2015() {
    Write-Host "Installing Visual Studio build tools 2015"

    Write-Host "  Running vswhere to get info about installed Visual Studio instances"
    [xml]$vsInfo = vswhere -latest -format xml
    $vsInstallerPath = $vsInfo.instances.instance.properties.setupEngineFilePath
    Write-Host "  Setup path: $vsInstallerPath"
    $vsInstallDir = $vsInfo.instances.instance.installationPath
    Write-Host "  Install dir: $vsInstallDir"
    $installerArgs = @("modify", "--installPath", "`"$vsInstallDir`"", "--add", "Microsoft.VisualStudio.Component.VC.140", "--downloadThenInstall", "--quiet")
    $process = Start-Process $vsInstallerPath $installerArgs -Wait -PassThru
    Write-Host "  VS installer exit code: $($process.ExitCode)"
    if ($process.ExitCode -ne 0) {
        throw "Error: Installing Visual Studio build tools 2015 failed"
    }
    Write-Host "Done: Installing Visual Studio build tools 2015"
}


# Main function
function Main() {
    if ($command -ieq "StoreReleaseMetaInfo") {
        StoreReleaseMetaInfo
    }
    elseif ($command -ieq "StoreReleaseNotes") {
        StoreReleaseNotes
    }
    elseif ($command -ieq "InstallVsBuildTools2015") {
        InstallVsBuildTools2015
    }
    else {
        throw "Unkown command: $command"
    }
}


Main
