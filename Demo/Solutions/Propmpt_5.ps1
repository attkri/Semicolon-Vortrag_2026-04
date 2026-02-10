#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Duplikat-Erkennung mit Hash-basierter Deduplizierung und Symlink-Ersetzung.

.DESCRIPTION
    Durchsucht den Quellordner rekursiv nach Dateien, identifiziert Duplikate per SHA256-Hash,
    verschiebt die erste Datei jeder Gruppe in den Zielordner und ersetzt alle weiteren Fundorte durch Symlinks.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$QuellOrdner = "Archiv",

    [Parameter()]
    [string]$ZielOrdner = "Originale"
)

# --- Fehlerbehandlung ---
$ErrorActionPreference = "Stop"

# --- Logging ---
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

# --- Pruefungen ---
if (-not (Test-Path -Path $QuellOrdner)) {
    throw "Quellordner nicht gefunden: $QuellOrdner"
}

# Zielordner erstellen falls noetig
if (-not (Test-Path -Path $ZielOrdner)) {
    New-Item -ItemType Directory -Path $ZielOrdner -Force | Out-Null
    Write-Log "Zielordner erstellt: $ZielOrdner"
}

# --- Tracking-Datei fuer Idempotenz ---
$trackingFile = Join-Path $ZielOrdner ".dedup_tracking.json"
$processedHashes = @{}

if (Test-Path $trackingFile) {
    try {
        $jsonContent = Get-Content $trackingFile -Raw
        $parsed = $jsonContent | ConvertFrom-Json
        $processedHashes = @{}
        foreach ($prop in $parsed.PSObject.Properties) {
            $processedHashes[$prop.Name] = $prop.Value
        }
        Write-Log "Tracking-Datei geladen: $($processedHashes.Count) bereits verarbeitete Hashes"
    } catch {
        Write-Log "Fehler beim Laden der Tracking-Datei, starte neu" "WARN"
        $processedHashes = @{}
    }
}

# --- Variablen ---
$hashTable = @{}       # Hash -> [Dateiobjekte]
$scannedFiles = 0
$duplicateGroups = 0
$createdSymlinks = 0
$skippedFiles = 0
$processedBytes = 0

# --- Pruefe Link-Unterstuetzung ---
function Test-SymlinkSupport {
    $testPath = Join-Path $env:TEMP "symlink_test_$(Get-Random).txt"
    $targetPath = Join-Path $env:TEMP "symlink_target_$(Get-Random).txt"
    "test" | Out-File -FilePath $targetPath
    
    try {
        New-Item -ItemType SymbolicLink -Path $testPath -Target $targetPath -ErrorAction Stop | Out-Null
        Remove-Item $testPath -Force
        Remove-Item $targetPath -Force
        return $true
    } catch {
        Remove-Item $targetPath -Force -ErrorAction SilentlyContinue
        return $false
    }
}

$canCreateSymlinks = Test-SymlinkSupport
if (-not $canCreateSymlinks) {
    Write-Log "Keine Symlink-Berechtigung gefunden. Verwende Hardlinks als Fallback." "WARN"
}

# --- Hilfsfunktion: Pruefe ob Datei ein Link ist ---
function Test-IsLink {
    param([string]$Path)
    try {
        $item = Get-Item $Path -ErrorAction Stop
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            return $true
        }
        if ($item.LinkType -eq "HardLink") {
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

# --- Hilfsfunktion: Eindeutigen Zielpfad generieren ---
function Get-UniqueTargetPath {
    param([string]$SourcePath, [string]$TargetDir)
    
    $fileName = Split-Path $SourcePath -Leaf
    $targetPath = Join-Path $TargetDir $fileName
    
    if (-not (Test-Path $targetPath)) {
        return $targetPath
    }
    
    $counter = 1
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    $extension = [System.IO.Path]::GetExtension($fileName)
    
    do {
        $newName = "${baseName}_${counter}${extension}"
        $targetPath = Join-Path $TargetDir $newName
        $counter++
    } while (Test-Path $targetPath)
    
    return $targetPath
}

# --- Phase 1: Alle Dateien sammeln und hashen ---
Write-Log "Phase 1: Durchsuche '$QuellOrdner' nach Dateien..."

$allFiles = Get-ChildItem -Path $QuellOrdner -File -Recurse | Where-Object {
    # Nur Dateien ausserhalb des Zielordners
    -not $_.FullName.StartsWith((Resolve-Path $ZielOrdner).Path)
}

Write-Log "Gefunden: $($allFiles.Count) Dateien"

foreach ($file in $allFiles) {
    $scannedFiles++
    $processedBytes += $file.Length
    
    # Pruefe ob Datei bereits ein Link ist
    if (Test-IsLink -Path $file.FullName) {
        Write-Log "Bereits ein Link (uebersprungen): $($file.FullName)"
        $skippedFiles++
        continue
    }
    
    # Hash berechnen
    $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256 | Select-Object -ExpandProperty Hash
    
    # Pruefe ob dieser Hash bereits verarbeitet wurde
    if ($processedHashes.ContainsKey($hash)) {
        Write-Log "Hash bereits bekannt, ueberspringe: $($file.FullName)"
        $skippedFiles++
        continue
    }
    
    if (-not $hashTable.ContainsKey($hash)) {
        $hashTable[$hash] = @()
    }
    $hashTable[$hash] += $file
}

Write-Log "Phase 1 abgeschlossen. $($hashTable.Count) eindeutige Hashes identifiziert."

# --- Phase 2: Duplikate verarbeiten ---
Write-Log "Phase 2: Verarbeite Duplikate..."

foreach ($hash in $hashTable.Keys) {
    $files = $hashTable[$hash]
    
    if ($files.Count -gt 1) {
        $duplicateGroups++
        
        # Erste Datei als Original
        $original = $files[0]
        $targetPath = Get-UniqueTargetPath -SourcePath $original.FullName -TargetDir $ZielOrdner
        
        # Original verschieben
        Move-Item -Path $original.FullName -Destination $targetPath -Force
        Write-Log "Original verschoben: $($original.FullName) -> $targetPath"
        
        # Hash als verarbeitet markieren
        $processedHashes[$hash] = $targetPath
        
        # Alle weiteren Dateien durch Links ersetzen
        for ($i = 1; $i -lt $files.Count; $i++) {
            $duplicate = $files[$i]
            $linkPath = $duplicate.FullName
            
            # Alte Datei loeschen
            Remove-Item -Path $linkPath -Force
            
            # Link erstellen
            try {
                if ($canCreateSymlinks) {
                    New-Item -ItemType SymbolicLink -Path $linkPath -Target $targetPath -Force | Out-Null
                    Write-Log "Symlink erstellt: $linkPath"
                } else {
                    New-Item -ItemType HardLink -Path $linkPath -Target $targetPath -Force | Out-Null
                    Write-Log "Hardlink erstellt: $linkPath"
                }
                $createdSymlinks++
            } catch {
                Write-Log "Fehler beim Erstellen des Links fuer $linkPath`: $_" "ERROR"
                throw
            }
        }
    } else {
        # Einzelne Datei ohne Duplikate
        $original = $files[0]
        $targetPath = Get-UniqueTargetPath -SourcePath $original.FullName -TargetDir $ZielOrdner
        
        Move-Item -Path $original.FullName -Destination $targetPath -Force
        Write-Log "Einzeldatei verschoben: $($original.FullName) -> $targetPath"
        
        $processedHashes[$hash] = $targetPath
    }
}

# --- Tracking-Datei speichern ---
$processedHashes | ConvertTo-Json | Out-File $trackingFile -Force
Write-Log "Tracking-Datei aktualisiert: $trackingFile"

# --- Zusammenfassung ---
$duplicateFiles = ($hashTable.Values | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Count - 1 } | Measure-Object -Sum).Sum

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  DEDUPLIZIERUNG ABGESCHLOSSEN" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Gescannte Dateien:     $scannedFiles"
Write-Host "Uebersprungen:         $skippedFiles"
Write-Host "Duplikat-Gruppen:      $duplicateGroups"
Write-Host "Duplikat-Dateien:      $duplicateFiles"
Write-Host "Erstellte Links:       $createdSymlinks"
Write-Host "Verarbeitete Daten:    $([math]::Round($processedBytes / 1MB, 2)) MB"
Write-Host "========================================" -ForegroundColor Green
