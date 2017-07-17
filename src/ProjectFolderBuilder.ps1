#requires -version 4
# TODO: convert in Module
<#
.SYNOPSIS
  [WIP] Automate creation of new software project building its folder structure.
  # TODO: remove WIP

.DESCRIPTION
  Create a series of predefined folders and relative README as base for every new software project. Inspired to http://hiltmon.com/blog/2012/06/30/project-folder-layout.

.PARAMETER RootProjectsPath
  Literal path to your projects-container folder.

.PARAMETER ProjectName
  The name of the project; (it will be the name of root folder of the project).

.PARAMETER Force
  Force script to: write; overwrite; not chech RootProjectsPath.

.PARAMETER NoReadme
  Prevent README insertion in every folder.

.INPUTS
  None.

.OUTPUTS
  Path of root of the new project folder.

.NOTES
  Version:        0.1
  Author:         Roberto Desideri
  Creation Date:  2017-07-17
  Purpose/Change: Initial script development

.EXAMPLE
  TODO:<Example explanation goes here>
  
  <Example goes here. Repeat this attribute for more than one example>
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

Param (
  # Literal path to your projects-container folder
  [Parameter(Mandatory = $true,
    Position = 0,
    HelpMessage = "Literal path to your projects-container folder.")]
  [ValidateNotNullOrEmpty()]
  [string]
  $RootProjectsPath,

  # Name of the project.
  [Parameter(Mandatory = $true,
    Position = 1,
    HelpMessage = "Name of the project.")]
  [ValidateNotNullOrEmpty()]
  [string]
  $ProjectName,
  
  # Force script to: write; overwrite; not chech RootProjectsPath.
  [Parameter(Mandatory = $false,
    HelpMessage = "Force script to: write; overwrite; not chech RootProjectsPath.")]
  [switch]
  $Force,
  
  # Prevent README insertion in every folder.
  [Parameter(Mandatory = $false,
    HelpMessage = "Prevent README insertion in every folder.")]
  [switch]
  $NoReadme
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = 'Stop'

#Import Modules & Snap-ins

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Any Global Declarations go here

#-----------------------------------------------------------[Functions]------------------------------------------------------------



function CreateAllReadme () {
  
  function UnderscoreToPath ($key) {
    # Convert the path in form of path_dir_foo present in FoldersReadme.psd1
    # keys to path/dir/foo for path purpose.
  
    if ($key -match '.+_.+') {
      $key = $key -replace '_', '\\'
    }
    return $key
  }

  foreach ($folderKey in $Script:foldersReadme.Keys) {
    $folderKey = UnderscoreToPath $folderKey
    $p = "$ProjectPath\$folderKey\README.md"
    $v = "# $($($folderKey[0]).ToString().ToUpper() + $folderKey.Substring(1)) Folder`n`n"
    $v += $foldersReadme.Item($folderKey)
    New-Item -Path $p -ItemType File -Force:$Force -Value $v | Out-Null
  }
}

function BuildFoldersRecursive ($thisHash, $lastPath) {
  if ($thisHash -and $lastPath) {
    foreach ($folder in $thisHash.Keys) {
      New-Item -Path $lastPath\$folder -ItemType Directory -Force:$Force | Out-Null
      if ($thisHash.Item($folderKey).Count -gt 0) {
        BuildFoldersRecursive $thisHash.Item($folderKey) $lastPath\$folder
      }
    }
  }
  else {
    foreach ($folderKey in $Script:folderStructure.Keys) {
      New-Item -Path $ProjectPath\$folderKey -ItemType Directory -Force:$Force | Out-Null
      if ($Script:folderStructure.Item($folderKey).Count -gt 0) {
        BuildFoldersRecursive $Script:folderStructure.Item($folderKey) $ProjectPath\$folderKey
      }
    }
  }
  
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Location handling
$OriginalLocation = Get-Location
Set-Location $PSScriptRoot

# Check if user has inserted ProjectName in RootProjectsPath...
if ($(Split-Path $RootProjectsPath) -eq $ProjectName) {
  Write-Warning "Found project name '$ProjectName' as leaf of project path '$RootProjectsPath'. Removing the duplicated folder..."
  $RootProjectsPath = Split-Path $RootProjectsPath -Parent
  Write-Information "The new RootProjectsPath is: '$RootProjectsPath'"
}

$Script:ProjectPath = Join-Path $RootProjectsPath $ProjectName

# Check if path already exists
if (Test-Path -Path $ProjectPath) {
  if (!$Force) {
    Write-Error "'$ProjectPath' dir already exists"
  }
  else {
    Write-Information "'$ProjectPath' dir will be replaced with a new empty project structure."
    Remove-Item $ProjectPath -Recurse -Force
    New-Item $ProjectPath -ItemType Directory -Force | Out-Null
  }
}

# Retrieve data
$Script:folderStructure = Import-PowerShellDataFile .\data\ProjectFolderStructure.psd1
$Script:foldersReadme = Import-PowerShellDataFile .\data\FoldersReadme.psd1

# Write-out folder structure
BuildFoldersRecursive

# Write-out README
if (!$NoReadme) {
  CreateAllReadme
}

Set-Location $OriginalLocation

Write-Information "All done!"
