<#
.SYNOPSIS
    Install or update hold-to-speedup.lua into an mpv.net config folder.

.DESCRIPTION
    mpv.net has no plugin manager, so scripts are plain files dropped into the
    config folder. This resolves that folder the same way mpv.net does --
    MPVNET_HOME, then portable_config next to mpvnet.exe, then %APPDATA%\mpv.net
    -- and copies the script (and, on first install, the sample options file)
    into it.

    Run it again any time to pull the latest version.

.PARAMETER Source
    Where to copy from: "github" downloads from this repository, "local" uses
    the files sitting next to this script.

.PARAMETER ConfigDir
    Override the auto-detected mpv.net config folder.

.EXAMPLE
    .\install-mpvnet.ps1
    .\install-mpvnet.ps1 -Source local
#>
[CmdletBinding()]
param(
    [ValidateSet("github", "local")]
    [string] $Source = "github",
    [string] $ConfigDir
)

$ErrorActionPreference = "Stop"

$RawBase = "https://raw.githubusercontent.com/starsdaisuki/mpv-hold-to-speedup/main"

function Resolve-MpvNetConfigDir {
    if ($env:MPVNET_HOME -and (Test-Path $env:MPVNET_HOME)) {
        return $env:MPVNET_HOME
    }

    # portable_config lives next to mpvnet.exe. Look where the shim points as
    # well as the usual install locations.
    $exeDirs = @()

    $cmd = Get-Command mpvnet.exe -ErrorAction SilentlyContinue
    if ($cmd) { $exeDirs += (Split-Path $cmd.Source -Parent) }

    $exeDirs += @(
        "$env:USERPROFILE\scoop\apps\mpv.net\current"
        "$env:ProgramFiles\mpv.net"
        "${env:ProgramFiles(x86)}\mpv.net"
        "$env:LOCALAPPDATA\Programs\mpv.net"
    )

    foreach ($dir in $exeDirs) {
        $portable = Join-Path $dir "portable_config"
        if (Test-Path $portable) { return $portable }
    }

    $roaming = Join-Path $env:APPDATA "mpv.net"
    if (Test-Path $roaming) { return $roaming }

    throw "Could not find an mpv.net config folder. Pass -ConfigDir explicitly."
}

if (-not $ConfigDir) { $ConfigDir = Resolve-MpvNetConfigDir }
Write-Host "Config folder: $ConfigDir"

$scriptsDir    = Join-Path $ConfigDir "scripts"
$scriptOptsDir = Join-Path $ConfigDir "script-opts"
foreach ($dir in @($scriptsDir, $scriptOptsDir)) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

$luaTarget  = Join-Path $scriptsDir    "hold-to-speedup.lua"
$confTarget = Join-Path $scriptOptsDir "hold-to-speedup.conf"

if ($Source -eq "github") {
    Write-Host "Downloading hold-to-speedup.lua from GitHub..."
    Invoke-WebRequest -Uri "$RawBase/hold-to-speedup.lua" -OutFile $luaTarget -UseBasicParsing
    if (-not (Test-Path $confTarget)) {
        Invoke-WebRequest -Uri "$RawBase/script-opts/hold-to-speedup.conf" -OutFile $confTarget -UseBasicParsing
    }
} else {
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    Copy-Item (Join-Path $here "hold-to-speedup.lua") $luaTarget -Force
    if (-not (Test-Path $confTarget)) {
        Copy-Item (Join-Path $here "script-opts\hold-to-speedup.conf") $confTarget -Force
    }
}

Write-Host "Installed: $luaTarget"
Write-Host "Options:   $confTarget  (left alone if it already existed)"
Write-Host "Restart mpv.net to load the script."
