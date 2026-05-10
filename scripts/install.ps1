# install.ps1 -- manifest.json + instructions.md -> SKILL.md build & deploy
#
# Usage:
#   .\scripts\install.ps1                                  # install all to ~/.claude/skills/
#   .\scripts\install.ps1 -Skills summarizer,code-review   # install subset
#   .\scripts\install.ps1 -Target <project>\.claude\skills # install to project
#   .\scripts\install.ps1 -DryRun                          # show what would change
#   .\scripts\install.ps1 -SkipValidate                    # skip validate.ps1

[CmdletBinding()]
param(
    [string]$Target = "$env:USERPROFILE\.claude\skills",
    [string[]]$Skills,
    [switch]$DryRun,
    [switch]$SkipValidate
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

# -- Step 1: validate.ps1 first (skippable) --
if (-not $SkipValidate) {
    Write-Host "-> Running validate.ps1..." -ForegroundColor Cyan
    & "$PSScriptRoot\validate.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "Validation failed. Aborting install. Use -SkipValidate to bypass." -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

# -- Step 2: discover skill folders (those with manifest.json) --
$skillDirs = Get-ChildItem -Path $root -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName 'manifest.json')
}

if ($Skills) {
    $skillDirs = $skillDirs | Where-Object { $_.Name -in $Skills }
    if ($skillDirs.Count -eq 0) {
        Write-Host "No matching skills: $($Skills -join ', ')" -ForegroundColor Red
        exit 1
    }
}

if ($skillDirs.Count -eq 0) {
    Write-Host "No skills found under $root" -ForegroundColor Yellow
    exit 0
}

Write-Host "-> Target: $Target" -ForegroundColor Cyan
Write-Host ""

# -- Step 3: build & deploy --
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$installed = 0
$skipped = 0
$wouldChange = 0

foreach ($dir in $skillDirs) {
    $name = $dir.Name
    $manifestPath = Join-Path $dir.FullName 'manifest.json'
    $instructionsPath = Join-Path $dir.FullName 'instructions.md'

    if (-not (Test-Path $instructionsPath)) {
        Write-Host "  [warn] $name : missing instructions.md, skipping" -ForegroundColor Yellow
        continue
    }

    try {
        $manifest = Get-Content -Raw -Encoding UTF8 $manifestPath | ConvertFrom-Json
    } catch {
        Write-Host "  [fail] $name : invalid manifest.json -- $_" -ForegroundColor Red
        continue
    }

    $instructions = Get-Content -Raw -Encoding UTF8 $instructionsPath

    # description priority: manifest.description > manifest.purpose
    $description = if ($manifest.description) { $manifest.description } else { $manifest.purpose }

    # build SKILL.md content
    $skillMd = @"
---
name: $($manifest.name)
description: $description
---

$($instructions.TrimEnd())

---

## Metadata

- **Version**: $($manifest.version)
- **Scope**: $($manifest.scope)
- **Source**: ``$($dir.FullName)``
- **Built by**: ``scripts/install.ps1``
"@

    # CRLF -> LF normalize
    $skillMd = $skillMd -replace "`r`n", "`n"

    $targetDir = Join-Path $Target $name
    $targetFile = Join-Path $targetDir 'SKILL.md'

    # idempotent check
    $existing = if (Test-Path $targetFile) {
        ([System.IO.File]::ReadAllText($targetFile)) -replace "`r`n", "`n"
    } else { '' }

    if ($existing -eq $skillMd) {
        Write-Host "  [skip] $name $($manifest.version) (no changes)" -ForegroundColor DarkGray
        $skipped++
        continue
    }

    if ($DryRun) {
        Write-Host "  [diff] $name $($manifest.version) -> $targetFile" -ForegroundColor Yellow
        $wouldChange++
    } else {
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        [System.IO.File]::WriteAllText($targetFile, $skillMd, $utf8NoBom)
        Write-Host "  [ok]   $name $($manifest.version) -> $targetFile" -ForegroundColor Green
        $installed++
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host "Dry run: $wouldChange would change, $skipped unchanged" -ForegroundColor Cyan
} else {
    Write-Host "Installed: $installed | Unchanged: $skipped | Target: $Target" -ForegroundColor Cyan
}
