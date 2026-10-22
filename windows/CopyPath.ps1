param(
    [ValidateSet('Copy','Recent','Open','Refresh')][string]$Action = 'Refresh',
    [string]$Path,
    [string]$EntryId
)
$ErrorActionPreference = 'Stop'
$root = Join-Path $env:LOCALAPPDATA 'CopyPath'
$historyFile = Join-Path $root 'history.json'
$scriptFile = Join-Path $root 'CopyPath.ps1'
$ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$classes = 'HKCU:\Software\Classes'

function Read-History {
    if (Test-Path -LiteralPath $historyFile) {
        return @(Get-Content -LiteralPath $historyFile -Raw -Encoding UTF8 | ConvertFrom-Json)
    }
    return @()
}

function Write-Clipboard([string]$value) {
    Add-Type -AssemblyName System.Windows.Forms
    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        try { [Windows.Forms.Clipboard]::SetText($value); return }
        catch { if ($attempt -eq 4) { throw }; Start-Sleep -Milliseconds 80 }
    }
}

function Remember([string]$value) {
    $rows = @(Read-History)
    $existing = @($rows | Where-Object { $_.Path -eq $value })
    $id = if ($existing.Count) { $existing[0].Id } else { [guid]::NewGuid().ToString('N') }
    $rows = @(@{Id=$id; Path=$value}) + @($rows | Where-Object { $_.Path -ne $value })
    $rows = @($rows | Select-Object -First 10)
    $temp = Join-Path $root 'history.tmp'
    ConvertTo-Json -InputObject $rows | Set-Content -LiteralPath $temp -Encoding UTF8
    Move-Item -LiteralPath $temp -Destination $historyFile -Force
}

function Refresh-Menus {
    $rows = @(Read-History)
    foreach ($kind in @('Recent','Open')) {
        $menu = "$classes\CopyPath.$kind\shell"
        if (Test-Path -LiteralPath $menu) { Remove-Item -LiteralPath $menu -Recurse -Force }
        New-Item -Path $menu -Force | Out-Null
        $index = 0
        foreach ($row in $rows) {
            $name = [IO.Path]::GetFileName($row.Path.TrimEnd('\'))
            if (!$name) { $name = $row.Path }
            $parent = [IO.Path]::GetDirectoryName($row.Path)
            if ($parent.Length -gt 32) { $parent = $parent.Substring(0,32) + '...' }
            if ($name.Length -gt 48) { $name = $name.Substring(0,30) + '...' + $name.Substring($name.Length-14) }
            $entry = Join-Path $menu ('{0:D2}' -f $index)
            New-Item -Path "$entry\command" -Force | Out-Null
            # Escape menu accelerators, but keep the real path untouched.
            Set-Item -LiteralPath $entry -Value (($name + ' - ' + $parent).Replace('&','&&'))
            $command = '"{0}" -NoProfile -NonInteractive -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "{1}" -Action {2} -EntryId {3}' -f $ps,$scriptFile,$kind,$row.Id
            Set-Item -LiteralPath "$entry\command" -Value $command
            $index++
        }
        if (!$rows.Count) {
            New-Item -Path "$menu\00\command" -Force | Out-Null
            Set-Item -LiteralPath "$menu\00" -Value '(No recent paths)'
            Set-Item -LiteralPath "$menu\00\command" -Value ('"{0}" -NoProfile -NonInteractive -WindowStyle Hidden -Command exit' -f $ps)
        }
    }
}

$mutex = New-Object Threading.Mutex($false, ('Local\CopyPath-' + [Security.Principal.WindowsIdentity]::GetCurrent().User.Value))
$locked = $false
try {
    try { $locked = $mutex.WaitOne(10000) } catch [Threading.AbandonedMutexException] { $locked = $true }
    if (!$locked) { throw 'Copy Path is busy. Please try again.' }
    switch ($Action) {
        'Copy' {
            if (!$Path -or ![IO.Path]::IsPathRooted($Path)) { throw 'An absolute path is required.' }
            $value = [IO.Path]::GetFullPath($Path)
            Write-Clipboard $value
            Remember $value
        }
        { $_ -in 'Recent','Open' } {
            $row = @(Read-History) | Where-Object { $_.Id -eq $EntryId } | Select-Object -First 1
            if (!$row) { throw 'This history entry is no longer available.' }
            if ($Action -eq 'Recent') { Write-Clipboard $row.Path; Remember $row.Path }
            else {
                if (!(Test-Path -LiteralPath $row.Path)) { throw 'This file or folder has moved or no longer exists.' }
                $info = New-Object Diagnostics.ProcessStartInfo
                $info.FileName = $row.Path
                $info.UseShellExecute = $true
                [Diagnostics.Process]::Start($info) | Out-Null
            }
        }
    }
    Refresh-Menus
} catch {
    # Successful operations are silent; failures remain diagnosable locally.
    $_.Exception.Message | Set-Content -LiteralPath (Join-Path $root 'last-error.txt') -Encoding UTF8
    exit 1
} finally {
    if ($locked) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
