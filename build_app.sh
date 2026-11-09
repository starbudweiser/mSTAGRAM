#!/bin/zsh
# Compile, signe et installe mSTAGRAM dans ~/Applications/Applications Personnelles.
set -e
cd "${0:A:h}"
APP="build/mSTAGRAM.app"; DEST="$HOME/Applications/Applications Personnelles"
rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -o "$APP/Contents/MacOS/mSTAGRAM" Sources/main.swift
cat > "$APP/Contents/Info.plist" <<P
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>mSTAGRAM</string>
<key>CFBundleDisplayName</key><string>mSTAGRAM</string>
<key>CFBundleIdentifier</key><string>fr.stephan.mstagram</string>
<key>CFBundleExecutable</key><string>mSTAGRAM</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSAppTransportSecurity</key><dict><key>NSAllowsArbitraryLoads</key><true/></dict>
</dict></plist>
P
[[ -f assets/AppIcon.icns ]] && cp assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
/Volumes/SKYRIM/TOOLS/MAC/_tools/sign_app.sh "$APP"
mkdir -p "$DEST"; rm -rf "$DEST/mSTAGRAM.app"; cp -R "$APP" "$DEST/"
echo "installé : $DEST/mSTAGRAM.app"
