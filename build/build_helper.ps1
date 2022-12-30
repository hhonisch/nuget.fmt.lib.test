#Requires -Version 5

param(
    # Generate package files
    [Parameter(Mandatory = $true, ParameterSetName = "GeneratePackageFiles")]
    [switch] $GeneratePackageFiles,
    # Package dir
    [Parameter(Mandatory = $true, ParameterSetName = "GeneratePackageFiles")]
    [string] $PackageDir,
    # Package ID
    [Parameter(Mandatory = $true, ParameterSetName = "GeneratePackageFiles")]
    [string] $PackageID,
    # Package version
    [Parameter(Mandatory = $true, ParameterSetName = "GeneratePackageFiles")]
    [string] $PackageVersion
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


# Generate package files
function GeneratePackageFiles($packageDir, $packageID, $packageVersion) {
    Write-Host "Generating NuGet package files in $packageDir..."

    # Create nuspec file
    $nuspecTemplatePath = Join-Path $packageDir "fmt.lib.nuspec.template"
    $nuspecPath = Join-Path $packageDir "$packageID.nuspec"
    Write-Host "  Generating $nuspecPath from $nuspecTemplatePath..."
    [xml] $nuspecXml = Get-Content $nuspecTemplatePath
    $nuspecXml.package.metadata.id = $packageID
    $nuspecXml.package.metadata.version = $packageVersion
    $nuspecXml.Save($nuspecPath)

    # Create targets file
    $targetsTemplatePath = Join-Path $packageDir "build/fmt.lib.targets.template"
    $targetsPath = Join-Path $packageDir "build/$packageID.targets"
    Copy-Item $targetsTemplatePath $targetsPath -Force
}


# Main function
function Main() {
    # Generate package files
    if ($GeneratePackageFiles) {
        GeneratePackageFiles $PackageDir $PackageID $PackageVersion
    }
}


Main
