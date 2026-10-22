#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="$PWD/build/Copy Path.app"
EXT="$APP/Contents/PlugIns/CopyPathFinder.appex"
mkdir -p "$APP/Contents/MacOS" "$EXT/Contents/MacOS"
export CLANG_MODULE_CACHE_PATH="$PWD/build/module-cache"
export SWIFT_MODULECACHE_PATH="$PWD/build/module-cache"
python3 - "$APP" "$EXT" <<'PY'
import plistlib, sys
from pathlib import Path
app, ext = map(Path, sys.argv[1:])
base = dict(CFBundleDevelopmentRegion='en', CFBundleInfoDictionaryVersion='6.0',
            CFBundleShortVersionString='1.2', CFBundleVersion='3', LSMinimumSystemVersion='13.0')
for directory, extra in [(app, dict(CFBundleIdentifier='local.uengine.CopyPath',
    CFBundleExecutable='CopyPath', CFBundleName='Copy Path', CFBundleDisplayName='Copy Path',
    CFBundlePackageType='APPL', NSPrincipalClass='NSApplication', LSUIElement=True,
    CFBundleURLTypes=[dict(CFBundleURLName='local.uengine.CopyPath.open', CFBundleURLSchemes=['uengine-copy-path'])])),
    (ext, dict(CFBundleIdentifier='local.uengine.CopyPath.FinderExtension',
    CFBundleExecutable='CopyPathFinder', CFBundleName='Copy Path', CFBundleDisplayName='Copy Path',
    CFBundlePackageType='XPC!', NSExtension=dict(NSExtensionPointIdentifier='com.apple.FinderSync',
    NSExtensionPrincipalClass='CopyPathFinderSync')))]:
    with (directory/'Contents/Info.plist').open('wb') as f: plistlib.dump(base | extra, f)
with open('build/sandbox.plist', 'wb') as f:
    plistlib.dump({'com.apple.security.app-sandbox': True}, f)
PY
xcrun swiftc Sources/FinderSync.swift -module-name CopyPathFinder -parse-as-library -application-extension \
    -framework Cocoa -framework FinderSync -Xlinker -e -Xlinker _NSExtensionMain \
    -o "$EXT/Contents/MacOS/CopyPathFinder"
xcrun swiftc Sources/main.swift -framework Cocoa -framework FinderSync -o "$APP/Contents/MacOS/CopyPath"
codesign --force --sign - --entitlements build/sandbox.plist "$EXT"
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"
echo "Built: $APP"
