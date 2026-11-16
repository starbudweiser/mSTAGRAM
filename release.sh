#!/bin/zsh
# Publie une version : compile, notarise (Apple), zippe puis crée la release GitHub.
# Usage : ./release.sh [--notes "texte"]   — la version vient de CFBundleShortVersionString (Resources/Info.plist).
set -euo pipefail
cd "$(dirname "$0")"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
TAG="v$VERSION"
DIST="$PWD/dist"
NOTES=""
[ "${1:-}" = "--notes" ] && NOTES="${2:-}"
git diff --quiet && git diff --cached --quiet || { echo "Modifications non commitées : commiter avant la release." >&2; exit 1; }
! git rev-parse "$TAG" >/dev/null 2>&1 || { echo "La version $TAG existe déjà." >&2; exit 1; }
git fetch -q origin main
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || { echo "Pas synchronisé avec origin/main (push manquant)." >&2; exit 1; }

NO_INSTALL=1 ./build_app.sh
rm -rf "$DIST"
DIST="$DIST" /Volumes/SKYRIM/TOOLS/MAC/_tools/notarize_app.sh build/mSTAGRAM.app
ASSET="mSTAGRAM-$VERSION-macOS.zip"
mv "$DIST/mSTAGRAM.zip" "$DIST/$ASSET"
(cd "$DIST" && shasum -a 256 "$ASSET" > "$ASSET.sha256")

if [ -z "$NOTES" ]; then
  NOTES_FILE="$DIST/notes.md"
  cat > "$NOTES_FILE" <<NOTES_EOF
<!-- notes:fr -->
## $VERSION
- Quatre nouveaux coloris titane (naturel par défaut). Mise à jour automatique depuis GitHub. Mention du DESKTOP MAC TOOLKIT dans « À propos ». README et licence complétés.
<!-- notes:en -->
## $VERSION
- Four new titanium finishes (natural by default). Automatic updates from GitHub. About window mentions the DESKTOP MAC TOOLKIT. README and license completed.
<!-- notes:es -->
## $VERSION
- Cuatro nuevos acabados de titanio (natural por defecto). Actualización automática desde GitHub. La ventana «Acerca de» menciona el DESKTOP MAC TOOLKIT. README y licencia completados.
<!-- notes:it -->
## $VERSION
- Quattro nuove finiture in titanio (naturale predefinita). Aggiornamento automatico da GitHub. La finestra «Informazioni» menziona il DESKTOP MAC TOOLKIT. README e licenza completati.
NOTES_EOF
  NOTES_ARGS=(--notes-file "$NOTES_FILE")
else NOTES_ARGS=(--notes "$NOTES"); fi

git tag "$TAG" && git push -q origin "$TAG"
gh release create "$TAG" "$DIST/$ASSET" "$DIST/$ASSET.sha256" --title "mSTAGRAM $VERSION" "${NOTES_ARGS[@]}"
echo "✓ https://github.com/starbudweiser/mSTAGRAM/releases/tag/$TAG"
