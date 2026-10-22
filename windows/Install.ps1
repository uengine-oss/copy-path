$ErrorActionPreference = 'Stop'
$root = Join-Path $env:LOCALAPPDATA 'CopyPath'
New-Item -ItemType Directory -Path $root -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'CopyPath.ps1') -Destination $root -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Uninstall.ps1') -Destination $root -Force
$ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$scriptFile = Join-Path $root 'CopyPath.ps1'
foreach ($type in @('*','Directory','Directory\Background','Drive')) {
    $base = "HKCU:\Software\Classes\$type\shell"
    $copy = "$base\CopyPath.Copy"
    New-Item -Path "$copy\command" -Force | Out-Null
    Set-Item -LiteralPath $copy -Value 'Copy Path'
    New-ItemProperty -LiteralPath $copy -Name MultiSelectModel -Value Single -Force | Out-Null
    $placeholder = if ($type -eq 'Directory\Background') { '%V' } else { '%1' }
    # A trailing slash before the closing quote prevents root-path quote parsing issues.
    $command = '"{0}" -NoProfile -NonInteractive -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "{1}" -Action Copy -Path "{2}\."' -f $ps,$scriptFile,$placeholder
    # Paths to files must not receive a directory suffix; quote with a trailing separator
    # only for Drive and Background, which always supply directories.
    if ($type -notin @('Drive','Directory\Background')) {
        $command = '"{0}" -NoProfile -NonInteractive -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "{1}" -Action Copy -Path "{2}"' -f $ps,$scriptFile,$placeholder
    }
    Set-Item -LiteralPath "$copy\command" -Value $command
    foreach ($kind in @('Recent','Open')) {
        $key = "$base\CopyPath.$kind"
        New-Item -Path $key -Force | Out-Null
        New-ItemProperty -LiteralPath $key -Name MUIVerb -Value "$kind Paths" -Force | Out-Null
        New-ItemProperty -LiteralPath $key -Name ExtendedSubCommandsKey -Value "CopyPath.$kind" -Force | Out-Null
    }
}
& $ps -NoProfile -NonInteractive -STA -ExecutionPolicy Bypass -File $scriptFile -Action Refresh
if ($LASTEXITCODE -ne 0) { throw 'Menu setup failed. See %LOCALAPPDATA%\CopyPath\last-error.txt.' }
Write-Host 'Installed. Right-click > Show more options (Shift+F10).'
Write-Host 'Copy Path / Recent Paths / Open Paths'
