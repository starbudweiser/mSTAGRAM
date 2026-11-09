# mSTAGRAM

## About
mSTAGRAM shows Instagram in its **phone version**, inside a window styled as an **iPhone 17 Pro Max** (titanium frame, Dynamic Island, status bar), on your Mac. It is a small personal tool by [starbudweiser](https://github.com/starbudweiser), independent from the Skyrim Mac Toolkit and not affiliated with Instagram or Meta.

Why: some Instagram settings (for example the profile link) are only editable from the phone version. mSTAGRAM presents itself as an iPhone, so the mobile layout is served. Instagram may still keep some settings reserved to its native app.

- Native macOS app in Swift (AppKit + WKWebView), Apple Silicon and Intel.
- Your login is kept between launches.
- Three finishes: Cosmic Orange, Deep Blue, Silver (Finish menu).
- Interface in French, English, Spanish and Italian (system language).
- Another site can be opened: `open -a mSTAGRAM --args https://example.com`.

## Build
```bash
./build_app.sh   # compiles, signs and installs to ~/Applications/Applications Personnelles
```

---

## Français
mSTAGRAM affiche Instagram en **version téléphone**, dans une fenêtre habillée en **iPhone 17 Pro Max** (cadre titane, îlot dynamique, barre d'état), sur le Mac. Petit outil personnel de starbudweiser, indépendant du Skyrim Mac Toolkit et non affilié à Instagram ni à Meta.

Pourquoi : certains réglages d'Instagram (par exemple le lien du profil) ne sont modifiables que depuis la version téléphone. mSTAGRAM se présente comme un iPhone. Instagram peut tout de même réserver certains réglages à son appli native.

- Appli macOS native en Swift (AppKit + WKWebView).
- Connexion conservée d'un lancement à l'autre.
- Trois coloris : Orange cosmique, Bleu intense, Argent (menu Coloris).
- Interface en français, anglais, espagnol et italien (langue du système).

## Licence / Licence
MIT
