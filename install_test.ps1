#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'

# Test that we can install the latest version at the default location.
Remove-Item "~\.wakflo" -Recurse -Force -ErrorAction SilentlyContinue
$env:WAKFLO_DIR = ""
$v = $null; .\install.ps1
~\.wakflo\bin\wakflo.exe --version

# Test that we can install a specific version at a custom location.
Remove-Item "~\wakflo-0.17.1" -Recurse -Force -ErrorAction SilentlyContinue
$env:WAKFLO_DIR = "$Home\wakflo-0.17.1"
$v = "0.17.1"; .\install.ps1
$WakfloVersion = ~\wakflo-0.17.1\bin\wakflo.exe --version
if (!($WakfloVersion -like '*0.17.1*')) {
  throw $WakfloVersion
}
