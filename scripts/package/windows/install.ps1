[CmdletBinding()]
param(
	[switch]$DryRun,
	[switch]$NoPause
)

$ErrorActionPreference = "Stop"

trap {
	Write-Host ""
	Write-Host "OBRA CHAMELEON INSTALLATION FAILED" -ForegroundColor Red
	Write-Host $_.Exception.Message -ForegroundColor Red
	if ($_.InvocationInfo.PositionMessage) {
		Write-Host $_.InvocationInfo.PositionMessage -ForegroundColor DarkGray
	}
	Write-Host ""
	Write-Host "Detected package root: $PackageRoot"
	Write-Host "Detected game root:    $GameRoot"
	Write-Host "Expected game file:    $GameExe"
	Write-Host ""
	if (-not $NoPause) {
		Read-Host "Press Enter to close this window"
	}
	exit 1
}
$ReShadeVersion = "6.7.3"
$ReShadeSetupUrl = "https://reshade.me/downloads/ReShade_Setup_$ReShadeVersion.exe"
$ReShadeSetupSha256 = "56791fd065358e899c581ebefe2ad871399b7c7ae83fb85e1154c08a75a44147"
$ReShadeDllSha256 = "059168b9d8aaa694a02a64342409fa26dfdf335035f2c0184cc61581deffc3bc"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PackageRoot = [IO.Path]::GetFullPath((Join-Path $ScriptDir ".."))
$GameRoot = $null
$Candidate = Get-Item -LiteralPath $PackageRoot
for ($Level = 0; $Level -lt 4 -and $null -ne $Candidate.Parent; $Level++) {
	$Candidate = $Candidate.Parent
	$CandidateBootstrap = Join-Path $Candidate.FullName "PenguinHotel.exe"
	$CandidateGameExe = Join-Path $Candidate.FullName "Chameleon\Binaries\Win64\PenguinHotel-Win64-Shipping.exe"
	if ((Test-Path -LiteralPath $CandidateBootstrap -PathType Leaf) -and (Test-Path -LiteralPath $CandidateGameExe -PathType Leaf)) {
		$GameRoot = $Candidate.FullName
		break
	}
}
if ($null -eq $GameRoot) {
	$GameRoot = [IO.Path]::GetFullPath((Join-Path $PackageRoot ".."))
}
$PayloadDir = Join-Path $PackageRoot "common"
$RuntimeDir = Join-Path $GameRoot "Chameleon\Binaries\Win64"
$GameExe = Join-Path $RuntimeDir "PenguinHotel-Win64-Shipping.exe"

function Write-Step {
	param([string]$Message)
	Write-Host $Message -ForegroundColor Cyan
}

function Stop-Install {
	param([string]$Message)
	throw $Message
}

function Get-Sha256 {
	param([string]$Path)
	return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Test-GameLayout {
	if (-not (Test-Path -LiteralPath (Join-Path $GameRoot "PenguinHotel.exe") -PathType Leaf)) {
		Stop-Install "PenguinHotel.exe was not found in: $GameRoot"
	}
	if (-not (Test-Path -LiteralPath $GameExe -PathType Leaf)) {
		Stop-Install "Shipping executable was not found: $GameExe"
	}
	if (-not (Test-Path -LiteralPath (Join-Path $GameRoot "Engine") -PathType Container)) {
		Stop-Install "The Unreal Engine directory was not found. Extract the ZIP directly into the game root."
	}
	if (-not (Test-Path -LiteralPath (Join-Path $PackageRoot "manifest.json") -PathType Leaf)) {
		Stop-Install "Package manifest is missing. Extract a fresh, complete copy of the ZIP."
	}
}

function Test-PayloadChecksums {
	$ChecksumFile = Join-Path $PayloadDir "PAYLOAD-SHA256SUMS"
	if (-not (Test-Path -LiteralPath $ChecksumFile -PathType Leaf)) {
		Stop-Install "Payload checksum file is missing."
	}
	foreach ($Line in Get-Content -LiteralPath $ChecksumFile) {
		if ([string]::IsNullOrWhiteSpace($Line)) {
			continue
		}
		if ($Line -notmatch '^([0-9a-fA-F]{64})\s+\*?(.+)$') {
			Stop-Install "Invalid checksum entry: $Line"
		}
		$Expected = $Matches[1].ToLowerInvariant()
		$RelativePath = $Matches[2] -replace '/', '\'
		$Path = Join-Path $PackageRoot $RelativePath
		if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
			Stop-Install "Payload file is missing: $RelativePath"
		}
		if ((Get-Sha256 $Path) -ne $Expected) {
			Stop-Install "Payload checksum failed: $RelativePath"
		}
	}
}

function Add-InstallPair {
	param(
		[string]$Source,
		[string]$Target
	)
	$script:InstallPairs += [PSCustomObject]@{
		Source = $Source
		Target = $Target
	}
}

function Test-InstallTarget {
	param($Pair)
	if (-not (Test-Path -LiteralPath $Pair.Target)) {
		return
	}
	if (-not (Test-Path -LiteralPath $Pair.Target -PathType Leaf)) {
		Stop-Install "Install target is not a regular file: $($Pair.Target)"
	}
	if ((Get-Sha256 $Pair.Source) -ne (Get-Sha256 $Pair.Target)) {
		Stop-Install "Existing file would be replaced: $($Pair.Target). Move or remove the existing ReShade installation before retrying."
	}
}

function Install-PayloadFile {
	param($Pair)
	if ((Test-Path -LiteralPath $Pair.Target -PathType Leaf) -and ((Get-Sha256 $Pair.Source) -eq (Get-Sha256 $Pair.Target))) {
		Write-Host "Already installed: $($Pair.Target)"
		return
	}
	if ($DryRun) {
		Write-Host "DRY-RUN: copy $($Pair.Source) -> $($Pair.Target)"
		return
	}
	$Parent = Split-Path -Parent $Pair.Target
	New-Item -ItemType Directory -Path $Parent -Force | Out-Null
	Copy-Item -LiteralPath $Pair.Source -Destination $Pair.Target
	Write-Host "Installed: $($Pair.Target)"
}

Write-Host "Obra Chameleon Windows Installer v0.2" -ForegroundColor Cyan
Write-Host "Script location: $($MyInvocation.MyCommand.Path)"
Write-Host "Package root:    $PackageRoot"
Write-Host "Game root:       $GameRoot"
Write-Host ""

Test-GameLayout
Write-Step "Verifying the shared shader payload..."
Test-PayloadChecksums

if (Get-Process -Name "PenguinHotel-Win64-Shipping" -ErrorAction SilentlyContinue) {
	Stop-Install "Meccha Chameleon is running. Close it before installation."
}

$InstallPairs = @()
Add-InstallPair (Join-Path $PayloadDir "ReShade.ini") (Join-Path $RuntimeDir "ReShade.ini")

$ShaderRoot = Join-Path $PayloadDir "Shaders"
Get-ChildItem -LiteralPath $ShaderRoot -Recurse -File | Where-Object { $_.Extension -in '.fx', '.fxh' } | Sort-Object FullName | ForEach-Object {
	$Relative = $_.FullName.Substring($ShaderRoot.Length).TrimStart('\', '/')
	Add-InstallPair $_.FullName (Join-Path (Join-Path $RuntimeDir "reshade-shaders\Shaders") $Relative)
}

Get-ChildItem -LiteralPath (Join-Path $PayloadDir "Presets") -File -Filter '*.ini' | Sort-Object Name | ForEach-Object {
	Add-InstallPair $_.FullName (Join-Path $RuntimeDir $_.Name)
}

foreach ($Pair in $InstallPairs) {
	Test-InstallTarget $Pair
}

$DxgiPath = Join-Path $RuntimeDir "dxgi.dll"
$RuntimeInstalled = $false
if (Test-Path -LiteralPath $DxgiPath -PathType Leaf) {
	if ((Get-Sha256 $DxgiPath) -ne $ReShadeDllSha256) {
		Stop-Install "An unrecognized dxgi.dll already exists: $DxgiPath. Resolve the existing overlay or ReShade installation before continuing."
	}
	$RuntimeInstalled = $true
	Write-Host "The tested ReShade $ReShadeVersion runtime is already installed."
}

if (-not $RuntimeInstalled) {
	$SetupDir = Join-Path $env:TEMP "Obra-Chameleon"
	$SetupPath = Join-Path $SetupDir "ReShade_Setup_$ReShadeVersion.exe"
	if ($DryRun) {
		Write-Host "DRY-RUN: download $ReShadeSetupUrl -> $SetupPath"
		Write-Host "DRY-RUN: launch the official ReShade setup UI"
	} else {
		New-Item -ItemType Directory -Path $SetupDir -Force | Out-Null
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		Write-Step "Downloading the official ReShade $ReShadeVersion setup program..."
		Invoke-WebRequest -UseBasicParsing -Uri $ReShadeSetupUrl -OutFile $SetupPath
		if ((Get-Sha256 $SetupPath) -ne $ReShadeSetupSha256) {
			Stop-Install "Official ReShade setup checksum mismatch."
		}

		Write-Host ""
		Write-Host "The official ReShade setup will open next." -ForegroundColor Yellow
		Write-Host "1. Select this game executable: $GameExe"
		Write-Host "2. Select Microsoft DirectX 10/11/12."
		Write-Host "3. Skip the optional effect-package download; Obra Chameleon supplies its own shaders."
		Write-Host "4. Finish and close the ReShade setup window. This script will then continue."
		Write-Host ""
		Read-Host "Press Enter to open the official ReShade setup"
		Start-Process -FilePath $SetupPath -Wait

		if (-not (Test-Path -LiteralPath $DxgiPath -PathType Leaf)) {
			Stop-Install "ReShade did not create $DxgiPath. Run the script again and select the shipping executable shown above."
		}
		if ((Get-Sha256 $DxgiPath) -ne $ReShadeDllSha256) {
			Stop-Install "The installed dxgi.dll does not match the tested ReShade $ReShadeVersion runtime."
		}
	}
}

Write-Step "Installing the Obra Chameleon shader and default preset..."
foreach ($Pair in $InstallPairs) {
	Install-PayloadFile $Pair
}

if ($DryRun) {
	Write-Host "Dry run complete. No files were changed."
} else {
	Write-Host "Installation complete." -ForegroundColor Green
}
Write-Host "Launch Meccha Chameleon normally through Steam."
Write-Host "Home opens ReShade, and Scroll Lock toggles the effect."
Write-Warning "Use private or solo play while anti-cheat compatibility remains unconfirmed."
Write-Host ""
if (-not $NoPause) {
	Read-Host "Press Enter to close this window"
}
