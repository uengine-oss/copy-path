$ErrorActionPreference = 'Stop'
foreach ($type in @('*','Directory','Directory\Background','Drive')) {
    foreach ($kind in @('Copy','Recent','Open')) {
        $key = "HKCU:\Software\Classes\$type\shell\CopyPath.$kind"
        if (Test-Path -LiteralPath $key) { Remove-Item -LiteralPath $key -Recurse -Force }
    }
}
foreach ($kind in @('Recent','Open')) {
    $key = "HKCU:\Software\Classes\CopyPath.$kind"
    if (Test-Path -LiteralPath $key) { Remove-Item -LiteralPath $key -Recurse -Force }
}
$root = Join-Path $env:LOCALAPPDATA 'CopyPath'
# Remove only this application's known files.
foreach ($name in @('CopyPath.ps1','Uninstall.ps1','history.json','history.tmp','last-error.txt')) {
    $file = Join-Path $root $name
    if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force }
}
Write-Host 'Copy Path removed.'
