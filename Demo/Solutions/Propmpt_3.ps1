# PowerShell Core 7.x script: dedupe-archiv.ps1
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ArchivePath = Join-Path $ScriptDir 'Archiv'
if (-not (Test-Path $ArchivePath)) {
    Write-Error "Archiv not found at $ArchivePath"
    exit 1
}
$OriginalsDir = Join-Path $ArchivePath 'Originale'
if (-not (Test-Path $OriginalsDir)) {
    try { New-Item -Path $OriginalsDir -ItemType Directory -Force | Out-Null } catch { Write-Error ("Unable to create Originale: {0}" -f $_); exit 1 }
}
function Get-FileHashSHA256([string]$path) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($path)
    try { $hash = $sha.ComputeHash($stream) } finally { $stream.Close(); $sha.Dispose() }
    return ([System.BitConverter]::ToString($hash)).Replace('-','').ToLowerInvariant()
}
$files = Get-ChildItem -Path $ArchivePath -File -Recurse -ErrorAction SilentlyContinue | Where-Object { -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) }
$hashmap = @{}
foreach ($f in $files) {
    try { $h = Get-FileHashSHA256 $f.FullName } catch { Write-Warning ("Hash failed: {0}: {1}" -f $f.FullName, $_); continue }
    if (-not $hashmap.ContainsKey($h)) { $hashmap[$h] = @() }
    $hashmap[$h] += $f.FullName
}
$groupsProcessed = 0
$filesMoved = 0
$symlinksCreated = 0
$errors = 0
foreach ($h in $hashmap.Keys) {
    $group = $hashmap[$h]
    if ($group.Count -lt 2) { continue }
    $groupsProcessed++
    $target = $null
    $existingInOriginale = $group | Where-Object { $_ -like "$OriginalsDir*" }
    if ($existingInOriginale) {
        $target = $existingInOriginale[0]
    } else {
        $candidate = ($group | Sort-Object)[0]
        $destName = [System.IO.Path]::GetFileName($candidate)
        $destPath = Join-Path $OriginalsDir $destName
        $i = 1
        while (Test-Path $destPath) { $base = [System.IO.Path]::GetFileNameWithoutExtension($destName); $ext = [System.IO.Path]::GetExtension($destName); $destPath = Join-Path $OriginalsDir ("{0}_{1}{2}" -f $base,$i,$ext); $i++ }
        try { Move-Item -Path $candidate -Destination $destPath -Force; $filesMoved++ } catch { Write-Warning ("Move failed {0} -> {1}: {2}" -f $candidate, $destPath, $_); $errors++; continue }
        $target = $destPath
    }
    foreach ($p in $group) {
        if ($p -eq $target) { if ($p -like "$OriginalsDir*") { continue } }
        try {
            if (Test-Path $p) {
                $item = Get-Item -LiteralPath $p -Force
                if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                    $linkTarget = $null
                    try { $linkTarget = (Get-Item -LiteralPath $p -Force).Target } catch {}
                    if ($linkTarget -and (Resolve-Path -LiteralPath $linkTarget -ErrorAction SilentlyContinue) -and ([System.IO.Path]::GetFullPath($linkTarget) -eq [System.IO.Path]::GetFullPath($target))) { continue }
                    Remove-Item -LiteralPath $p -Force
                } else { Remove-Item -LiteralPath $p -Force }
            }
            New-Item -ItemType SymbolicLink -Path $p -Target $target | Out-Null
            $symlinksCreated++
        } catch { Write-Warning ("Failed creating symlink at {0} -> {1}: {2}" -f $p, $target, $_); $errors++ }
    }
}
Write-Output "Processed duplicate groups: $groupsProcessed"
Write-Output "Files moved to Originale: $filesMoved"
Write-Output "Symlinks created: $symlinksCreated"
if ($errors -gt 0) { Write-Warning "Errors encountered: $errors" }
