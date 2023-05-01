#!/usr/bin/env pwsh
# Copyright 2023 the Wakflo AI authors. All rights reserved. MIT license.
# TODO(everyone): Keep this script simple and easily auditable.

$ErrorActionPreference = 'Stop'

if ($v) {
  $Version = "${v}" # "v${v}"
}
if ($args.Length -eq 1) {
  $Version = $args.Get(0)
}

$WakfloInstall = $env:WAKFLO_DIR
$WakfloDir = if ($WakfloInstall) {
  "$WakfloInstall"
} else {
  "$Home\.wakflo"
}

$WakfloInstaller = "$Home\temp-wakflo-installer.exe"
$WakfloBinDir = "$WakfloDir\bin"
$Target = 'windows'

$allowedExecutionPolicy = @('Unrestricted', 'RemoteSigned', 'ByPass')
if ((Get-ExecutionPolicy).ToString() -notin $allowedExecutionPolicy) {
  Write-Output "PowerShell requires an execution policy in [$($allowedExecutionPolicy -join ", ")] to run the Wakflo Installer."
  Write-Output "For example, to set the execution policy to 'RemoteSigned' please run :"
  Write-Output "'Set-ExecutionPolicy RemoteSigned -scope CurrentUser'"
  break
}

# GitHub requires TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$WakfloInstallerUri = if (!$Version) {
  Write-Host "Fetching latest Wakflo release..."
  $Response = Invoke-RestMethod -Uri 'https://api.github.com/repos/wakflo/wakflo-cli/releases/latest' -UseBasicParsing
  ( 
    $Response.assets | 
    Where-Object { $_.name -eq "wakflo-${Target}.exe" } | 
    Select-Object -First 1 
  ).browser_download_url
} else {
  "https://github.com/wakflo/wakflo-cli/releases/download/${Version}/wakflo-${Target}.exe"
}

if (!(Test-Path $WakfloDir)) {
  New-Item $WakfloDir -ItemType Directory | Out-Null
}

if (Test-Path $WakfloInstaller) {
  Remove-Item $WakfloInstaller
}

Write-Host "Downloading Wakflo..."

Invoke-WebRequest $WakfloInstallerUri -OutFile $WakfloInstaller -UseBasicParsing

Write-Output "Installing Wakflo..."

Start-Process $WakfloInstaller -Wait -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /DIR=`"$WakfloDir`" /SP-"
Remove-Item $WakfloInstaller

Write-Output "Adding Wakflo to ENV:Path $WakfloBinDir..."

$User = [EnvironmentVariableTarget]::User
$Path = [Environment]::GetEnvironmentVariable('Path', $User)
if (!(";$Path;".ToLower() -like "*;$WakfloBinDir;*".ToLower())) {
  Write-Output "Adding Wakflo bin directory ($WakfloBinDir) to Environment path..."
  [Environment]::SetEnvironmentVariable('Path', "$Path;$WakfloBinDir", $User)
  $Env:Path += ";$WakfloBinDir"
}

Write-Host "Wakflo installed" -ForegroundColor Green

Write-Host "Finished" -ForegroundColor Green

Write-Output "Run '$WakfloBinDir\wakflo --help' to get started"