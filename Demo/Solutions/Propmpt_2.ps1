# PowerShell Core 7.x Skript: Duplikate per SHA256 erkennen, Originale verschieben, Symlinks anlegen

param(
    [string]$ArchivPfad = (Join-Path $PSScriptRoot 'Archiv'),
    [string]$OriginalePfad = (Join-Path $PSScriptRoot 'Originale'),
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$msg, [string]$level = "INFO")
    $color = switch ($level) {
        "INFO"  { "Gray" }
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }
    Write-Host "[$level] $msg" -ForegroundColor $color
}

# 1. Dateien im Archiv rekursiv suchen
Write-Log "Durchsuche $ArchivPfad nach Dateien..."
$alleDateien = Get-ChildItem -Path $ArchivPfad -File -Recurse -ErrorAction Stop

if ($alleDateien.Count -eq 0) {
    Write-Log "Keine Dateien im Archiv gefunden." "WARN"
    return
}

# 2. SHA256-Hashes berechnen und Duplikate finden
$hashMap = @{}
foreach ($datei in $alleDateien) {
    try {
        # Symlinks überspringen
        if ($datei.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            continue
        }
        $hash = Get-FileHash -Path $datei.FullName -Algorithm SHA256 | Select-Object -ExpandProperty Hash
        if (-not $hashMap.ContainsKey($hash)) {
            $hashMap[$hash] = @()
        }
        $hashMap[$hash] += $datei
    } catch {
        Write-Log "Fehler beim Hashen: $($_.Exception.Message) ($($datei.FullName))" "ERROR"
    }
}

# 3. Originale-Ordner anlegen
if (-not (Test-Path $OriginalePfad)) {
    try {
        New-Item -ItemType Directory -Path $OriginalePfad -Force | Out-Null
        Write-Log "Ordner 'Originale' erstellt: $OriginalePfad"
    } catch {
        Write-Log "Fehler beim Erstellen von $OriginalePfad: $($_.Exception.Message)" "ERROR"
        return
    }
}

# 4. Duplikatgruppen verarbeiten
[int]$gruppen = 0
[int]$symlinks = 0
foreach ($hash in $hashMap.Keys) {
    $dateien = $hashMap[$hash]
    if ($dateien.Count -lt 2) { continue } # Nur Gruppen mit Duplikaten

    $gruppen++
    $original = $dateien[0]
    $zielName = $original.Name
    $zielPfad = Join-Path $OriginalePfad $zielName

    # Falls Original schon im Ziel liegt, überspringen
    if (-not ($original.FullName -eq $zielPfad)) {
        try {
            if ($WhatIf) {
                Write-Log "Würde $($original.FullName) nach $zielPfad verschieben"
            } else {
                Move-Item -Path $original.FullName -Destination $zielPfad -Force
                Write-Log "Original verschoben: $zielPfad"
            }
        } catch {
            Write-Log "Fehler beim Verschieben: $($_.Exception.Message)" "ERROR"
            continue
        }
    } else {
        Write-Log "Original liegt bereits in $zielPfad"
    }

    # Für alle anderen Duplikate Symlink anlegen
    foreach ($dupl in $dateien | Where-Object { $_.FullName -ne $zielPfad }) {
        # Prüfen, ob bereits Symlink existiert und korrekt zeigt
        if ($dupl.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            try {
                $target = (Get-Item $dupl.FullName -Force).Target
                if ($target -eq $zielPfad) {
                    Write-Log "Symlink existiert bereits: $($dupl.FullName) -> $zielPfad"
                    continue
                } else {
                    Write-Log "Symlink zeigt auf falsches Ziel, wird ersetzt: $($dupl.FullName)" "WARN"
                    if (-not $WhatIf) { Remove-Item $dupl.FullName -Force }
                }
            } catch {
                Write-Log "Fehler beim Prüfen/Entfernen von Symlink: $($_.Exception.Message)" "ERROR"
                continue
            }
        } else {
            if (-not $WhatIf) { Remove-Item $dupl.FullName -Force }
        }

        try {
            if ($WhatIf) {
                Write-Log "Würde Symlink anlegen: $($dupl.FullName) -> $zielPfad"
            } else {
                New-Item -ItemType SymbolicLink -Path $dupl.FullName -Target $zielPfad | Out-Null
                Write-Log "Symlink erstellt: $($dupl.FullName) -> $zielPfad"
                $symlinks++
            }
        } catch {
            Write-Log "Fehler beim Anlegen von Symlink: $($_.Exception.Message)" "ERROR"
        }
    }
}

# 5. Zusammenfassung
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Duplikat-Bereinigung abgeschlossen" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Dateien gescannt:     $($alleDateien.Count)"
Write-Host " Duplikat-Gruppen:     $gruppen"
Write-Host " Symlinks erstellt:    $symlinks"
Write-Host " Originale-Ordner:     $OriginalePfad"
Write-Host "========================================" -ForegroundColor Cyan