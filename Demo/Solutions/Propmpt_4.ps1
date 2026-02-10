[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceDir,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$resolvedSource = (Resolve-Path -Path $SourceDir).Path
if (-not (Test-Path -LiteralPath $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}
$resolvedTarget = (Resolve-Path -Path $TargetDir).Path

$files = Get-ChildItem -Path $resolvedSource -File -Recurse
$scannedFiles = $files.Count

if ($scannedFiles -eq 0) {
    Write-Host "Keine Dateien im Quellordner gefunden."
    Write-Host "Zusammenfassung:"
    Write-Host "  Gescannte Dateien : 0"
    Write-Host "  Duplikat-Gruppen  : 0"
    Write-Host "  Erstellte Symlinks: 0"
    return
}

$hashEntries = foreach ($file in $files) {
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    [PSCustomObject]@{
        Hash = $hash
        Path = $file.FullName
        Name = $file.Name
    }
}

$duplicateGroups = $hashEntries |
    Group-Object -Property Hash |
    Where-Object { $_.Count -gt 1 }

$symlinkCount = 0

function Get-UniqueTargetPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory,
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        [Parameter(Mandatory = $true)]
        [string]$Hash
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $extension = [System.IO.Path]::GetExtension($FileName)
    $candidate = Join-Path -Path $Directory -ChildPath $FileName
    $index = 1

    while (Test-Path -LiteralPath $candidate) {
        $candidate = Join-Path -Path $Directory -ChildPath ("{0}_{1}_{2}{3}" -f $baseName, $Hash.Substring(0, 8), $index, $extension)
        $index++
    }

    return $candidate
}

foreach ($group in $duplicateGroups) {
    $groupItems = $group.Group | Sort-Object -Property Path
    $primaryItem = $groupItems[0]

    $targetPath = Get-UniqueTargetPath -Directory $resolvedTarget -FileName $primaryItem.Name -Hash $group.Name

    Move-Item -LiteralPath $primaryItem.Path -Destination $targetPath

    for ($i = 1; $i -lt $groupItems.Count; $i++) {
        $duplicatePath = $groupItems[$i].Path

        Remove-Item -LiteralPath $duplicatePath -Force
        New-Item -ItemType SymbolicLink -Path $duplicatePath -Target $targetPath | Out-Null
        $symlinkCount++
    }
}

Write-Host "Zusammenfassung:"
Write-Host ("  Gescannte Dateien : {0}" -f $scannedFiles)
Write-Host ("  Duplikat-Gruppen  : {0}" -f $duplicateGroups.Count)
Write-Host ("  Erstellte Symlinks: {0}" -f $symlinkCount)
