#!/bin/zsh
# Compile, signe et installe mSTAGRAM dans ~/Applications/Applications Personnelles.
set -e
cd "${0:A:h}"
APP="build/mSTAGRAM.app"; DEST="$HOME/Applications/Applications Personnelles"
rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -o "$APP/Contents/MacOS/mSTAGRAM" Sources/*.swift
cp Resources/Info.plist "$APP/Contents/Info.plist"
[[ -f assets/AppIcon.icns ]] && cp assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
/Volumes/SKYRIM/TOOLS/MAC/_tools/sign_app.sh "$APP"
if [[ -z "${NO_INSTALL:-}" ]]; then mkdir -p "$DEST"; rm -rf "$DEST/mSTAGRAM.app"; cp -R "$APP" "$DEST/"; echo "installé : $DEST/mSTAGRAM.app"; fi
