#requires -Version 7.0
<#
.Dedupe-Archiv.ps1
- Sucht rekursiv in .\Demo\Archiv
- Identifiziert Duplikate per SHA256
- Verschiebt je Hash-Gruppe 1 Datei nach .\Demo\Originale
- Ersetzt alle Fundorte (inkl. des verschobenen) durch Symlinks auf das Original
- Idempotent: erkennt passende Symlinks und überspringt sie
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()] [string] $ArchivePath   = ".\Demo\Archiv",
    [Parameter()] [string] $OriginalsPath = ".\Demo\Originale",
    [Parameter()] [string] $LogPath       = ".\Demo\dedupe.log"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------- Logging ----------
function Write-Log {
    param(
        [Parameter(Mandatory)] [string] $Message,
        [ValidateSet("INFO","WARN","ERROR","DEBUG")] [string] $Level = "INFO"
    )
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
    $line = "[$ts] [$Level] $Message"
    Write-Host $line
    try {
        $dir = Split-Path -Parent $LogPath
        if ($dir) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Add-Content -LiteralPath $LogPath -Value $line
    } catch {
        Write-Host "[$ts] [WARN] Logging failed: $($_.Exception.Message)"
    }
}

function Is-ReparsePoint([System.IO.FileSystemInfo] $Item) {
    return [bool]($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
}

function Normalize-Path([string] $Path) {
    try { return [System.IO.Path]::GetFullPath($Path).ToLowerInvariant() }
    catch { return $Path.ToLowerInvariant() }
}

function Resolve-LinkTargetFullPath {
    param(
        [Parameter(Mandatory)] [string] $LinkPath,
        [Parameter(Mandatory)] [string] $Target
    )
    # Target kann relativ zum Link-Verzeichnis sein
    if ([System.IO.Path]::IsPathRooted($Target)) {
        return Normalize-Path $Target
    }
    $baseDir = Split-Path -Parent $LinkPath
    return Normalize-Path (Join-Path $baseDir $Target)
}

function Ensure-Symlink {
    param(
        [Parameter(Mandatory)] [string] $LinkPath,
        [Parameter(Mandatory)] [string] $TargetPath
    )

    $targetNorm = Normalize-Path $TargetPath

    if (Test-Path -LiteralPath $LinkPath) {
        $item = Get-Item -LiteralPath $LinkPath -Force

        if (Is-ReparsePoint $item) {
            # In PS7 hat ein Symlink i.d.R. LinkType/Target
            if ($null -ne $item.PSObject.Properties["LinkType"] -and $item.LinkType -eq "SymbolicLink") {
                $t = @($item.Target)[0]
                if ($null -ne $t) {
                    $existingNorm = Resolve-LinkTargetFullPath -LinkPath $LinkPath -Target $t
                    if ($existingNorm -eq $targetNorm) {
                        return @{ Status = "Skipped"; Reason = "Symlink already correct" }
                    }
                }
                return @{ Status = "Skipped"; Reason = "Symlink exists but target differs" }
            }

            return @{ Status = "Skipped"; Reason = "Reparse point exists (not a symlink or unknown type)" }
        }

        # Normale Datei/Ordner: entfernen und ersetzen
        if ($PSCmdlet.ShouldProcess($LinkPath, "Remove existing item and create symlink")) {
            Remove-Item -LiteralPath $LinkPath -Force
        } else {
            return @{ Status = "Skipped"; Reason = "WhatIf/ShouldProcess" }
        }
    } else {
        if (-not $PSCmdlet.ShouldProcess($LinkPath, "Create symlink")) {
            return @{ Status = "Skipped"; Reason = "WhatIf/ShouldProcess" }
        }
    }

    try {
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath -Force | Out-Null
        return @{ Status = "Created"; Reason = "" }
    } catch {
        return @{ Status = "Error"; Reason = $_.Exception.Message }
    }
}

# ---------- Start ----------
Write-Log "Start. ArchivePath=$ArchivePath OriginalsPath=$OriginalsPath" "INFO"

try {
    if (-not (Test-Path -LiteralPath $ArchivePath)) {
        throw "Archive path not found: $ArchivePath"
    }
    New-Item -ItemType Directory -Path $OriginalsPath -Force | Out-Null
} catch {
    Write-Log "Initialization failed: $($_.Exception.Message)" "ERROR"
    throw
}

# Scan: nur echte Dateien (keine Symlinks/ReparsePoints), sonst Hashen wir ggf. Targets/Loop
$files = @()
try {
    $files = Get-ChildItem -LiteralPath $ArchivePath -File -Recurse -Force |
             Where-Object { -not (Is-ReparsePoint $_) }
} catch {
    Write-Log "Scan failed: $($_.Exception.Message)" "ERROR"
    throw
}

$scanned = $files.Count
Write-Log "Scanned files (non-links): $scanned" "INFO"

# Hashing & Grouping
$hashToPaths = @{}  # string -> List[string]
foreach ($f in $files) {
    try {
        $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
        if (-not $hashToPaths.ContainsKey($h)) {
            $hashToPaths[$h] = [System.Collections.Generic.List[string]]::new()
        }
        $hashToPaths[$h].Add($f.FullName) | Out-Null
    } catch {
        Write-Log "Hash failed: $($f.FullName) :: $($_.Exception.Message)" "ERROR"
    }
}

$dupGroups = $hashToPaths.GetEnumerator() | Where-Object { $_.Value.Count -ge 2 }
$dupGroupCount = @($dupGroups).Count

$symlinksCreated = 0
$symlinksSkipped = 0
$symlinksErrors  = 0
$groupsProcessed = 0

foreach ($g in $dupGroups) {
    $hash  = $g.Key
    $paths = $g.Value  # insertion order
    if ($paths.Count -lt 2) { continue }

    $groupsProcessed++

    # Zielname kollisionsarm: <HASH>_<ersterDateiname>
    $firstPath = $paths[0]
    $leaf      = Split-Path -Leaf $firstPath
    $destPath  = Join-Path $OriginalsPath ("{0}_{1}" -f $hash, $leaf)

    # Falls Ziel bereits existiert, nehmen wir es als Canonical
    if (-not (Test-Path -LiteralPath $destPath)) {
        # Wenn firstPath nicht mehr existiert (z.B. schon verarbeitet), versuchen wir anderes Duplikat als Quelle
        $sourcePath = $null
        foreach ($p in $paths) {
            if (Test-Path -LiteralPath $p) {
                $it = Get-Item -LiteralPath $p -Force
                if (-not (Is-ReparsePoint $it)) { $sourcePath = $p; break }
            }
        }

        if ($null -eq $sourcePath) {
            Write-Log "Group $hash: no movable source found (all links/missing). Skipping move." "WARN"
        } else {
            try {
                if ($PSCmdlet.ShouldProcess($sourcePath, "Move to $destPath")) {
                    Move-Item -LiteralPath $sourcePath -Destination $destPath -Force
                    Write-Log "Group $hash: moved source to Originals: $destPath" "INFO"
                }
            } catch {
                Write-Log "Group $hash: move failed ($sourcePath -> $destPath): $($_.Exception.Message)" "ERROR"
                continue
            }
        }
    } else {
        Write-Log "Group $hash: canonical already exists: $destPath" "DEBUG"
    }

    # An allen Fundorten Symlink setzen (inkl. ehem. Quelle)
    foreach ($p in $paths) {
        $res = Ensure-Symlink -LinkPath $p -TargetPath $destPath
        switch ($res.Status) {
            "Created" { $symlinksCreated++; Write-Log "Symlink created: $p -> $destPath" "DEBUG" }
            "Skipped" { $symlinksSkipped++; Write-Log "Symlink skipped: $p ($($res.Reason))" "DEBUG" }
            "Error"   { $symlinksErrors++;  Write-Log "Symlink error: $p :: $($res.Reason)" "ERROR" }
        }
    }
}

Write-Log "Done." "INFO"
Write-Host ""
Write-Host "Summary 📌"
Write-Host "  Scanned files:        $scanned"
Write-Host "  Duplicate groups:     $dupGroupCount"
Write-Host "  Groups processed:     $groupsProcessed"
Write-Host "  Symlinks created:     $symlinksCreated"
Write-Host "  Symlinks skipped:     $symlinksSkipped"
Write-Host "  Symlinks errors:      $symlinksErrors"
Write-Host ""
Write-Log "Summary: scanned=$scanned dupGroups=$dupGroupCount symlinksCreated=$symlinksCreated skipped=$symlinksSkipped errors=$symlinksErrors" "INFO"
