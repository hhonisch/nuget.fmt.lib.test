#Requires -Version 5

param(
    # Generate package files
    [Parameter(Mandatory = $true, ParameterSetName = "GeneratePackageFiles")]
    [switch] $GeneratePackageFiles,
    # Generate build targets for testing
    [Parameter(Mandatory = $true, ParameterSetName = "GenerateTestBuildTargets")]
    [switch] $GenerateTestBuildTargets,
    # Input dir
    [Parameter(Mandatory = $true, ParameterSetName = "GeneratePackageFiles")]
    [Parameter(Mandatory = $true, ParameterSetName = "GenerateTestBuildTargets")]
    [string] $InputDir,
    # Package ID
    [Parameter(Mandatory = $true, ParameterSetName = "GeneratePackageFiles")]
    [Parameter(Mandatory = $true, ParameterSetName = "GenerateTestBuildTargets")]
    [string] $PackageID,
    # Package version
    [Parameter(Mandatory = $true, ParameterSetName = "GeneratePackageFiles")]
    [Parameter(Mandatory = $true, ParameterSetName = "GenerateTestBuildTargets")]
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


# Generate build targets for testing
function GenerateTestBuildTargets($buildDir, $packageID, $packageVersion) {
    Write-Host "Generating targets for testing in $buildDir..."

    # Create targets file
    $srcPath = Join-Path $buildDir "Directory.Build.targets.template"
    $destPath = Join-Path $buildDir "Directory.Build.targets"
    Write-Host "  Generating $destPath from $srcPath..."
    [xml] $targetsXml = Get-Content $srcPath
    $targetsXml.Project.Import.Project = "packages\$packageId.$packageVersion\build\$packageId.targets"
    $targetsXml.Save($destPath)
}


# Main function
function Main {
    # Generate package files
    if ($GeneratePackageFiles) {
        GeneratePackageFiles $InputDir $PackageID $PackageVersion
    }

    # Generate build targets for testing
    if ($GenerateTestBuildTargets) {
        GenerateTestBuildTargets $InputDir $PackageID $PackageVersion
    }

}


Main
