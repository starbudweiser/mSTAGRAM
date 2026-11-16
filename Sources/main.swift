// mSTAGRAM — Instagram en version téléphone (iPhone) dans une fenêtre sur le Mac. Un autre site peut être passé en argument.
import Cocoa
import WebKit

// MARK: - Langues (fr, en, es, it : mêmes clés ; langue du système, anglais par défaut)
enum L10n {
    static let lang: String = {
        let code = (Locale.preferredLanguages.first ?? "en").prefix(2).lowercased()
        return ["fr", "en", "es", "it"].contains(String(code)) ? String(code) : "en"
    }()
    static let table: [String: [String: String]] = [
        "fr": ["skin.titanium": "Titane naturel", "skin.black": "Titane noir", "skin.white": "Titane blanc", "skin.desert": "Titane désert", "menu.skin": "Coloris", "skin.orange": "Orange cosmique", "skin.blue": "Bleu intense", "skin.silver": "Argent", "menu.close": "Fermer", "menu.minimize": "Réduire", "menu.about": "À propos de mSTAGRAM", "menu.quit": "Quitter mSTAGRAM", "menu.nav": "Navigation",
               "menu.reload": "Recharger", "menu.back": "Précédent", "menu.home": "Accueil", "menu.window": "Fenêtre",
               "about.title": "À propos", "about.version": "Version %@ (%@)",
               "about.tagline": "Instagram en version téléphone, dans une fenêtre sur le Mac.",
               "about.authors": "starbudweiser", "about.license": "Licence MIT",
               "about.disclaimer": "Outil personnel indépendant, non affilié à Instagram ni à Meta."],
        "en": ["skin.titanium": "Natural Titanium", "skin.black": "Black Titanium", "skin.white": "White Titanium", "skin.desert": "Desert Titanium", "menu.skin": "Finish", "skin.orange": "Cosmic Orange", "skin.blue": "Deep Blue", "skin.silver": "Silver", "menu.close": "Close", "menu.minimize": "Minimize", "menu.about": "About mSTAGRAM", "menu.quit": "Quit mSTAGRAM", "menu.nav": "Navigation",
               "menu.reload": "Reload", "menu.back": "Back", "menu.home": "Home", "menu.window": "Window",
               "about.title": "About", "about.version": "Version %@ (%@)",
               "about.tagline": "Instagram in its phone version, in a window on your Mac.",
               "about.authors": "starbudweiser", "about.license": "MIT licence",
               "about.disclaimer": "Independent personal tool, not affiliated with Instagram or Meta."],
        "es": ["skin.titanium": "Titanio natural", "skin.black": "Titanio negro", "skin.white": "Titanio blanco", "skin.desert": "Titanio desierto", "menu.skin": "Acabado", "skin.orange": "Naranja cósmico", "skin.blue": "Azul intenso", "skin.silver": "Plata", "menu.close": "Cerrar", "menu.minimize": "Minimizar", "menu.about": "Acerca de mSTAGRAM", "menu.quit": "Salir de mSTAGRAM", "menu.nav": "Navegación",
               "menu.reload": "Recargar", "menu.back": "Atrás", "menu.home": "Inicio", "menu.window": "Ventana",
               "about.title": "Acerca de", "about.version": "Versión %@ (%@)",
               "about.tagline": "Instagram en su versión de móvil, en una ventana del Mac.",
               "about.authors": "starbudweiser", "about.license": "Licencia MIT",
               "about.disclaimer": "Herramienta personal independiente, sin relación con Instagram ni Meta."],
        "it": ["skin.titanium": "Titanio naturale", "skin.black": "Titanio nero", "skin.white": "Titanio bianco", "skin.desert": "Titanio deserto", "menu.skin": "Finitura", "skin.orange": "Arancione cosmico", "skin.blue": "Blu intenso", "skin.silver": "Argento", "menu.close": "Chiudi", "menu.minimize": "Riduci a icona", "menu.about": "Informazioni su mSTAGRAM", "menu.quit": "Esci da mSTAGRAM", "menu.nav": "Navigazione",
               "menu.reload": "Ricarica", "menu.back": "Indietro", "menu.home": "Home", "menu.window": "Finestra",
               "about.title": "Informazioni", "about.version": "Versione %@ (%@)",
               "about.tagline": "Instagram nella versione per telefono, in una finestra sul Mac.",
               "about.authors": "starbudweiser", "about.license": "Licenza MIT",
               "about.disclaimer": "Strumento personale indipendente, non affiliato a Instagram né a Meta."],
    ]
    static func t(_ key: String, _ args: CVarArg...) -> String {
        let s = table[lang]?[key] ?? table["en"]?[key] ?? key
        return args.isEmpty ? s : String(format: s, arguments: args)
    }
}

// Nom de l'appli : le « m » initial prend la couleur de son logo (magenta). Jamais dans un menu déroulant.
let brandColor = NSColor(srgbRed: 0.859, green: 0.153, blue: 0.467, alpha: 1)
func brandName(size: CGFloat) -> NSAttributedString {
    let s = NSMutableAttributedString(string: "mSTAGRAM", attributes: [.font: NSFont.boldSystemFont(ofSize: size), .foregroundColor: NSColor.labelColor])
    s.addAttribute(.foregroundColor, value: brandColor, range: NSRange(location: 0, length: 1))
    return s
}

// MARK: - Fenêtre « À propos » (structure du modèle Socle)
@MainActor
enum About {
    static var window: NSWindow?
    static func show() {
        if window == nil { window = make() }
        window?.center(); window?.makeKeyAndOrderFront(nil)
    }
    static func label(_ text: String, size: CGFloat = 12, bold: Bool = false, secondary: Bool = false) -> NSTextField {
        let f = NSTextField(wrappingLabelWithString: text)
        let p = NSMutableParagraphStyle(); p.alignment = .center
        f.attributedStringValue = NSAttributedString(string: text, attributes: [
            .font: bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size), .paragraphStyle: p,
            .foregroundColor: secondary ? NSColor.secondaryLabelColor : NSColor.labelColor])
        f.alignment = .center; f.preferredMaxLayoutWidth = 300; f.isSelectable = false
        f.translatesAutoresizingMaskIntoConstraints = false
        f.widthAnchor.constraint(lessThanOrEqualToConstant: 300).isActive = true
        return f
    }
    static func make() -> NSWindow {
        let info = Bundle.main.infoDictionary ?? [:]
        let icon = NSImageView(image: NSApp.applicationIconImage)
        icon.imageScaling = .scaleProportionallyUpOrDown; icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 84).isActive = true; icon.heightAnchor.constraint(equalToConstant: 84).isActive = true
        let name = NSTextField(labelWithAttributedString: brandName(size: 17)); name.alignment = .center
        let views: [NSView] = [icon, name,
            label(L10n.t("about.version", info["CFBundleShortVersionString"] as? String ?? "?", info["CFBundleVersion"] as? String ?? "?"), secondary: true),
            label(L10n.t("about.tagline")), label(L10n.t("about.authors"), bold: true), label(L10n.t("about.license")),
            label(L10n.t("about.disclaimer"), secondary: true)]
        let stack = NSStackView(views: views)
        stack.orientation = .vertical; stack.alignment = .centerX; stack.spacing = 12
        stack.setCustomSpacing(6, after: views[1]); stack.setCustomSpacing(18, after: views[2])
        stack.edgeInsets = NSEdgeInsets(top: 28, left: 28, bottom: 28, right: 28)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.widthAnchor.constraint(equalToConstant: 356).isActive = true
        let w = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = L10n.t("about.title"); w.isReleasedWhenClosed = false
        let content = NSView(); content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor), stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor), stack.bottomAnchor.constraint(equalTo: content.bottomAnchor)])
        w.contentView = content
        return w
    }
}


// MARK: - Habillage iPhone 17 Pro Max (écran 440×956 pt, cadre titane, îlot dynamique)
enum Finish: String, CaseIterable {
    case titanium, black, white, desert, orange, blue, silver
    var colors: (NSColor, NSColor) {
        switch self {
        case .titanium: return (NSColor(srgbRed: 0.74, green: 0.70, blue: 0.65, alpha: 1), NSColor(srgbRed: 0.46, green: 0.43, blue: 0.39, alpha: 1))
        case .black:    return (NSColor(srgbRed: 0.30, green: 0.30, blue: 0.32, alpha: 1), NSColor(srgbRed: 0.09, green: 0.09, blue: 0.10, alpha: 1))
        case .white:    return (NSColor(srgbRed: 0.93, green: 0.92, blue: 0.90, alpha: 1), NSColor(srgbRed: 0.70, green: 0.69, blue: 0.67, alpha: 1))
        case .desert:   return (NSColor(srgbRed: 0.80, green: 0.68, blue: 0.56, alpha: 1), NSColor(srgbRed: 0.52, green: 0.40, blue: 0.30, alpha: 1))
        case .orange: return (NSColor(srgbRed: 0.93, green: 0.52, blue: 0.27, alpha: 1), NSColor(srgbRed: 0.58, green: 0.24, blue: 0.08, alpha: 1))
        case .blue:   return (NSColor(srgbRed: 0.27, green: 0.35, blue: 0.50, alpha: 1), NSColor(srgbRed: 0.09, green: 0.13, blue: 0.22, alpha: 1))
        case .silver: return (NSColor(srgbRed: 0.90, green: 0.91, blue: 0.93, alpha: 1), NSColor(srgbRed: 0.60, green: 0.61, blue: 0.65, alpha: 1))
        }
    }
}

let screenW: CGFloat = 440, screenH: CGFloat = 956, bezel: CGFloat = 13
let deviceW = screenW + 2 * bezel, deviceH = screenH + 2 * bezel
let statusH: CGFloat = 54, homeH: CGFloat = 24
let pageBg = NSColor(srgbRed: 0.047, green: 0.055, blue: 0.071, alpha: 1)

final class FlippedView: NSView { override var isFlipped: Bool { true } }

final class DeviceWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class DeviceView: NSView {
    var finish: Finish = .orange { didSet { needsDisplay = true } }
    override var isFlipped: Bool { true }
    override func draw(_ r: NSRect) {
        let body = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 72, yRadius: 72)
        let (a, b) = finish.colors
        NSGradient(colors: [a, b, a])?.draw(in: body, angle: -60)
        NSColor.white.withAlphaComponent(0.35).setStroke(); body.lineWidth = 1.5; body.stroke()
        let inner = NSBezierPath(roundedRect: bounds.insetBy(dx: 6, dy: 6), xRadius: 66, yRadius: 66)
        NSColor.black.setFill(); inner.fill()
    }
}

final class StatusBar: NSView {
    let time = NSTextField(labelWithString: "")
    var timer: Timer?
    override var isFlipped: Bool { true }
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true; layer?.backgroundColor = pageBg.cgColor
        time.font = NSFont.systemFont(ofSize: 17, weight: .semibold); time.textColor = .white; time.alignment = .center
        time.frame = NSRect(x: 44, y: 17, width: 70, height: 22); addSubview(time)
        var x = frame.width - 38
        for (name, w) in [("battery.100", 28.0), ("wifi", 22.0), ("cellularbars", 22.0)] {
            let iv = NSImageView(image: NSImage(systemSymbolName: name, accessibilityDescription: nil) ?? NSImage())
            iv.contentTintColor = .white; iv.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            x -= CGFloat(w) + 4; iv.frame = NSRect(x: x, y: 19, width: CGFloat(w), height: 18); addSubview(iv)
        }
        tick(); timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in self?.tick() }
    }
    required init?(coder: NSCoder) { fatalError() }
    func tick() { let f = DateFormatter(); f.dateFormat = "HH:mm"; time.stringValue = f.string(from: Date()) }
}

final class IslandView: NSView {
    override var isFlipped: Bool { true }
    override func draw(_ r: NSRect) { NSColor.black.setFill(); NSBezierPath(roundedRect: bounds, xRadius: bounds.height / 2, yRadius: bounds.height / 2).fill() }
}
final class HomeBar: NSView {
    override var isFlipped: Bool { true }
    override func draw(_ r: NSRect) {
        NSColor.white.withAlphaComponent(0.9).setFill()
        NSBezierPath(roundedRect: NSRect(x: (bounds.width - 139) / 2, y: bounds.height - 13, width: 139, height: 5), xRadius: 2.5, yRadius: 2.5).fill()
    }
}

// MARK: - Appli
let iPhoneUA = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"

final class Delegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate {
    var window: NSWindow!
    var web: WKWebView!
    var device: DeviceView!

    func applicationDidFinishLaunching(_ n: Notification) {
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .default()                       // connexion conservée d'un lancement à l'autre
        cfg.defaultWebpagePreferences.preferredContentMode = .mobile
        web = WKWebView(frame: .zero, configuration: cfg)
        web.customUserAgent = iPhoneUA
        web.navigationDelegate = self; web.uiDelegate = self
        web.allowsBackForwardNavigationGestures = true
        window = DeviceWindow(contentRect: NSRect(x: 0, y: 0, width: deviceW, height: deviceH), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false; window.backgroundColor = .clear; window.hasShadow = true
        window.isMovableByWindowBackground = true; window.title = "mSTAGRAM"
        let dev = DeviceView(frame: NSRect(x: 0, y: 0, width: deviceW, height: deviceH))
        dev.finish = Finish(rawValue: UserDefaults.standard.string(forKey: "finish") ?? "") ?? .titanium
        device = dev
        // écran aux coins arrondis
        let scr = FlippedView(frame: NSRect(x: bezel, y: bezel, width: screenW, height: screenH)); scr.wantsLayer = true
        scr.layer?.cornerRadius = 56; scr.layer?.masksToBounds = true; scr.layer?.backgroundColor = pageBg.cgColor
        web.frame = NSRect(x: 0, y: statusH, width: screenW, height: screenH - statusH - homeH); scr.addSubview(web)
        scr.addSubview(StatusBar(frame: NSRect(x: 0, y: 0, width: screenW, height: statusH)))
        let bottom = HomeBar(frame: NSRect(x: 0, y: screenH - homeH, width: screenW, height: homeH)); bottom.wantsLayer = true
        bottom.layer?.backgroundColor = pageBg.cgColor; scr.addSubview(bottom)
        scr.addSubview(IslandView(frame: NSRect(x: (screenW - 126) / 2, y: 11, width: 126, height: 37)))
        dev.addSubview(scr)
        window.contentView = dev
        window.center(); window.setFrameAutosaveName("mSTAGRAM-device")
        let arg = CommandLine.arguments.dropFirst().first
        let url = URL(string: arg ?? "https://www.instagram.com/") ?? URL(string: "https://www.instagram.com/")!
        web.load(URLRequest(url: url))
        window.makeKeyAndOrderFront(nil)
        buildMenu()
    }

    func buildMenu() {
        let main = NSMenu(); NSApp.mainMenu = main
        func submenu(_ title: String, _ items: [(String, Selector, String, AnyObject?)]) {
            let it = NSMenuItem(); main.addItem(it)
            let m = NSMenu(title: title); it.submenu = m
            for (t, a, k, target) in items { let mi = NSMenuItem(title: t, action: a, keyEquivalent: k); mi.target = target; m.addItem(mi) }
        }
        submenu("mSTAGRAM", [(L10n.t("menu.about"), #selector(showAbout), "", self),
                             (L10n.t("menu.quit"), #selector(NSApplication.terminate(_:)), "q", nil)])
        submenu(L10n.t("menu.skin"), Finish.allCases.map { (L10n.t("skin." + $0.rawValue), #selector(setFinish(_:)), "", self) })
        submenu(L10n.t("menu.window"), [(L10n.t("menu.minimize"), #selector(NSWindow.miniaturize(_:)), "m", nil), (L10n.t("menu.close"), #selector(NSWindow.performClose(_:)), "w", nil)])
        submenu(L10n.t("menu.nav"), [(L10n.t("menu.reload"), #selector(reload), "r", self),
                                      (L10n.t("menu.back"), #selector(back), "[", self),
                                      (L10n.t("menu.home"), #selector(home), "h", self)])
    }
    @objc func setFinish(_ sender: NSMenuItem) {
        let i = sender.menu?.index(of: sender) ?? 0
        let f = Finish.allCases[i]; device.finish = f; UserDefaults.standard.set(f.rawValue, forKey: "finish")
    }
    @objc func showAbout() { About.show() }
    @objc func reload() { web.reload() }
    @objc func back() { web.goBack() }
    @objc func home() { web.load(URLRequest(url: URL(string: "https://www.instagram.com/")!)) }
    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }
    // liens qui s'ouvrent dans un nouvel onglet : dans la même fenêtre
    func webView(_ w: WKWebView, createWebViewWith c: WKWebViewConfiguration, for a: WKNavigationAction, windowFeatures f: WKWindowFeatures) -> WKWebView? {
        if a.targetFrame == nil { w.load(a.request) }; return nil
    }
}

let app = NSApplication.shared
let delegate = Delegate(); app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
