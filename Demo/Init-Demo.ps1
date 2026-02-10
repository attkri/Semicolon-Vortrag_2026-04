#Requires -Version 7.0
<#
.SYNOPSIS
    Baut die Demo-Ordnerstruktur für den Semicolon-Vortrag auf oder setzt sie zurück.
.DESCRIPTION
    1. Löscht den Ordner Demo\Archiv (falls vorhanden) und erstellt ihn neu mit Unterordnern.
    2. Löscht den Ordner Demo\Originale (falls vorhanden).
    3. Kopiert Dateien aus Demo\Test-Daten in die Archiv-Unterordner – teilweise unter anderen Namen,
       so dass bewusst Duplikate an verschiedenen Orten entstehen.
    4. Gibt eine Zusammenfassung aus.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$demoRoot = $PSScriptRoot
$archivRoot = Join-Path $demoRoot   'Archiv'
$originale  = Join-Path $demoRoot   'Originale'
$testDaten  = Join-Path $demoRoot   'Test-Daten'

# --- 1. Archiv zurücksetzen ---
if (Test-Path $archivRoot) {
    Remove-Item $archivRoot -Recurse -Force
    Write-Host "[Reset] Archiv gelöscht." -ForegroundColor Yellow
}

$unterordner = @(
    (Join-Path $archivRoot 'Projekte\Projekt-Alpha')
    (Join-Path $archivRoot 'Projekte\Projekt-Beta')
    (Join-Path $archivRoot 'Backup\2025-Q4')
    (Join-Path $archivRoot 'Backup\2026-Q1')
    (Join-Path $archivRoot 'Austausch')
)

foreach ($ordner in $unterordner) {
    New-Item -ItemType Directory -Path $ordner -Force | Out-Null
}
Write-Host "[OK] Archiv-Struktur erstellt ($($unterordner.Count) Ordner)." -ForegroundColor Green

# --- 2. Originale löschen ---
if (Test-Path $originale) {
    Remove-Item $originale -Recurse -Force
    Write-Host "[Reset] Originale gelöscht." -ForegroundColor Yellow
}

# --- 3. Dateien verteilen (bewusst Duplikate erzeugen) ---
$quelldateien = Get-ChildItem -Path $testDaten -File
if ($quelldateien.Count -eq 0) {
    Write-Warning "Keine Dateien in $testDaten gefunden - Demo-Ordner ist leer."
    return
}

# Verteilungsplan: [Quelldatei-Name] -> @([Zielordner-Index, Zieldateiname], ...)
# Jede Quelldatei wird an 2-3 Orte kopiert, teilweise unter anderem Namen.
$verteilung = @()

foreach ($datei in $quelldateien) {
    $name = $datei.Name
    $ext  = $datei.Extension

    # Original an Ort 1
    $verteilung += [PSCustomObject]@{
        Quelle = $datei.FullName
        Ziel   = Join-Path $unterordner[0] $name
    }

    # Duplikat an Ort 2 (gleicher Name)
    $verteilung += [PSCustomObject]@{
        Quelle = $datei.FullName
        Ziel   = Join-Path $unterordner[2] $name
    }

    # Duplikat an Ort 3 (anderer Name, gleicher Inhalt)
    $kopierName = "$($datei.BaseName)_Kopie$ext"
    $verteilung += [PSCustomObject]@{
        Quelle = $datei.FullName
        Ziel   = Join-Path $unterordner[4] $kopierName
    }
}

$kopiert = 0
foreach ($eintrag in $verteilung) {
    Copy-Item -Path $eintrag.Quelle -Destination $eintrag.Ziel -Force
    $kopiert++
}

# --- 4. Zusammenfassung ---
$eindeutig = $quelldateien.Count
$gesamt    = $kopiert

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Demo bereit!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Quelldateien:     $eindeutig"
Write-Host " Kopien verteilt:  $gesamt (in $($unterordner.Count) Ordnern)"
Write-Host " Duplikate:        $($gesamt - $eindeutig)"
Write-Host " Archiv-Pfad:      $archivRoot"
Write-Host "========================================" -ForegroundColor Cyan
