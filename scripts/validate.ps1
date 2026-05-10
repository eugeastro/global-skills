# validate.ps1 -- manifest.json schema validation + basic integrity checks
#
# Usage:
#   .\scripts\validate.ps1
#
# Exit code: 1 if errors > 0, else 0 (install.ps1 depends on this)

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent

$skillDirs = Get-ChildItem -Path $root -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName 'manifest.json')
}

$errors = 0
$warnings = 0
$ok = 0

foreach ($dir in $skillDirs) {
    $name = $dir.Name
    $manifestPath = Join-Path $dir.FullName 'manifest.json'
    $instructionsPath = Join-Path $dir.FullName 'instructions.md'
    $issues = @()
    $warns = @()

    # -- parse manifest --
    try {
        $manifest = Get-Content -Raw -Encoding UTF8 $manifestPath | ConvertFrom-Json
    } catch {
        Write-Host "[FAIL] $name : invalid JSON in manifest.json" -ForegroundColor Red
        Write-Host "       $_" -ForegroundColor Red
        $errors++
        continue
    }

    # -- required fields --
    foreach ($field in 'name', 'version', 'scope', 'purpose', 'input', 'output', 'boundaries') {
        if (-not $manifest.PSObject.Properties[$field]) {
            $issues += "missing required field: $field"
        }
    }

    # -- name == folder name --
    if ($manifest.name -and $manifest.name -ne $name) {
        $issues += "manifest.name '$($manifest.name)' != folder '$name'"
    }

    # -- version format --
    if ($manifest.version -and $manifest.version -notmatch '^v\d+(\.\d+)?$') {
        $issues += "version '$($manifest.version)' must match pattern v<N>(.<M>) (e.g. v1, v1.1)"
    }

    # -- scope value --
    if ($manifest.scope -and $manifest.scope -notin 'global', 'project') {
        $issues += "scope '$($manifest.scope)' must be 'global' or 'project'"
    }

    # -- boundaries structure --
    if ($manifest.boundaries) {
        if (-not $manifest.boundaries.does) {
            $issues += "boundaries.does is required (what this skill does)"
        }
        if (-not $manifest.boundaries.does_not) {
            $issues += "boundaries.does_not is required (boundary against neighboring skills)"
        }
    }

    # -- instructions.md exists & non-empty --
    if (-not (Test-Path $instructionsPath)) {
        $issues += "missing instructions.md"
    } elseif ((Get-Item $instructionsPath).Length -eq 0) {
        $issues += "instructions.md is empty"
    }

    # -- description recommended (install.ps1 falls back to purpose if absent) --
    if (-not $manifest.description) {
        $warns += "no 'description' field -- install.ps1 will fall back to 'purpose' for SKILL.md frontmatter"
    }

    # -- failure_modes recommended --
    if (-not $manifest.failure_modes) {
        $warns += "no 'failure_modes' declared (recommended)"
    }

    # -- output --
    if ($issues.Count -gt 0) {
        Write-Host "[FAIL] $name" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "       - $issue" -ForegroundColor Red
        }
        $errors++
    } elseif ($warns.Count -gt 0) {
        Write-Host "[warn] $name $($manifest.version)" -ForegroundColor Yellow
        foreach ($warn in $warns) {
            Write-Host "       - $warn" -ForegroundColor Yellow
        }
        $warnings++
        $ok++
    } else {
        Write-Host "[ok]   $name $($manifest.version)" -ForegroundColor Green
        $ok++
    }
}

Write-Host ""
Write-Host "Validation: $($skillDirs.Count) skills | $ok ok | $warnings warnings | $errors errors" -ForegroundColor Cyan

if ($errors -gt 0) {
    exit 1
} else {
    exit 0
}
