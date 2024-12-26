<#
.SYNOPSIS
Script to create Lambda layers with Docker or Podman.

.DESCRIPTION
This script creates Lambda layers for AWS using Docker or Podman. It allows to 
install specified packages directly or from a requirements file (requirements.txt or package.json).

.PARAMETER layername
The name of the layer to create.

.PARAMETER runtime
The AWS Lambda runtime to use (e.g. python3.12, nodejs14.x).
- PYTHON: “python3.6”,“python3.7”,“python3.8”,“python3.9”,“python3.10”,“python3.11”,"python3.12”
- NODEJS: “nodejs10.x”,“nodejs12.x”,“nodejs14.x”,“nodejs16.x”,“nodejs18.x”,"nodejs20.x”

.PARAMETER packages
List of packages to install (only if requirementsFile is not used).

.PARAMETER requirementsFile
Path to the requirements file (requirements.txt for Python, package.json for Node.js).

.PARAMETER zipOnly
If specified, only creates the ZIP file without uploading it to AWS.

.PARAMETER containerEngine
Engine container to use: “docker” (default) or “podman”.

.EXAMPLE
.\create-layer.ps1 -layername “mi-layer-python” -runtime “python3.12” -packages “fastapi”, “mangum” -zipOnly

.EXAMPLE
.\create-layer.ps1 -layername “mi-layer-node” -runtime “nodejs14.x” -requirementsFile “path/to/package.json” -containerEngine podman

.NOTES
Make sure you have Docker or Podman installed and configured, as well as the AWS CLI if you want to upload the layer to AWS.
#>

param(
    [Parameter(Mandatory=$true)][string]$layername,
    [Parameter(Mandatory=$true)][string]$runtime,
    [Parameter(ParameterSetName="Packages", Mandatory=$true)][string[]]$packages,
    [Parameter(ParameterSetName="RequirementsFile")][string]$requirementsFile,
    [switch]$zipOnly,
    [ValidateSet("docker", "podman")][string]$containerEngine = "docker"
)

$ErrorActionPreference = "Stop"

Write-Host "================================="

Write-Host "Layer name: $layername"
Write-Host "Runtime: $runtime"
if ($PSCmdlet.ParameterSetName -eq "Packages") {
    Write-Host "Packages: $($packages -join ' ')"
} else {
    Write-Host "Archivo requirements: $requirementsFile"
}
Write-Host "Only Zip, not AWS uploading: $zipOnly"
Write-Host "Container engine: $containerEngine"

Write-Host "================================="

$host_temp_dir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_.FullName }

$support_python_runtime = @("python3.6","python3.7","python3.8","python3.9","python3.10","python3.11","python3.12")
$support_node_runtime = @("nodejs10.x","nodejs12.x","nodejs14.x","nodejs16.x","nodejs18.x","nodejs20.x")

if ($support_node_runtime -contains $runtime) {
    $installation_path = "nodejs"
    $container_image = "public.ecr.aws/sam/build-$runtime`:latest"
    Write-Host "👷 Preparing layer..."
    if ($PSCmdlet.ParameterSetName -eq "Packages") {
        $packages_string = $packages -join ' '
        $install_command = "npm install --prefix $installation_path --save $packages_string"
    } else {
        Copy-Item $requirementsFile -Destination "$host_temp_dir\package.json"
        $install_command = "npm install --prefix $installation_path"
    }
    & $containerEngine run --rm -v "${host_temp_dir}:/lambda-layer:Z" -w "/lambda-layer" $container_image /bin/bash -c "mkdir $installation_path && $install_command && zip -r lambda-layer.zip *"
}
elseif ($support_python_runtime -contains $runtime) {
    $installation_path = "python"
    $container_image = "public.ecr.aws/sam/build-$runtime`:latest"
    Write-Host "👷 Preparing layer..."
    if ($PSCmdlet.ParameterSetName -eq "Packages") {
        $packages_string = $packages -join ' '
        $install_command = "pip install $packages_string -t $installation_path"
    } else {
        Copy-Item $requirementsFile -Destination "$host_temp_dir\requirements.txt"
        $install_command = "pip install -r requirements.txt -t $installation_path"
    }
    & $containerEngine run --rm -v "${host_temp_dir}:/lambda-layer:Z" -w "/lambda-layer" $container_image /bin/bash -c "mkdir $installation_path && $install_command && zip -r lambda-layer.zip * -x '*/__pycache__/*'"
}
else {
    Write-Host "✖️ Invalid runtime"
    exit 1
}

if ($zipOnly) {

    if ($support_node_runtime -contains $runtime) {
        $destination = Join-Path -Path $PWD -ChildPath "${layername}_${runtime}_lambda_layer_.zip"
    }
    elseif ($support_python_runtime -contains $runtime) {
        $destination = Join-Path -Path $PWD -ChildPath "${layername}_${runtime}_lambda_layer.zip"
    }
    Copy-Item -Path "${host_temp_dir}\lambda-layer.zip" -Destination $destination
    Write-Host "💾 Archivo ZIP del Layer creado en: $destination"
}
else {
    Write-Host "☁️ Subiendo Layer a AWS"
    aws lambda publish-layer-version --layer-name $layername --compatible-runtimes $runtime --zip-file "fileb://${host_temp_dir}/lambda-layer.zip"
}

Write-Host "🔚 Finishing..."
Remove-Item -Recurse -Force $host_temp_dir

Write-Host "💪 Ready!"
