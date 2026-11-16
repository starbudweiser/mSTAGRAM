// mSTAGRAM — mise à jour depuis les releases GitHub : recherche, téléchargement, vérification de la signature, remplacement.
import AppKit
import Foundation

@MainActor
final class Updater {
    static let shared = Updater()

    enum State: Equatable {
        case idle, checking, upToDate
        case available(version: String)
        case downloading
        case failed(String)
    }

    static let repo = "starbudweiser/mSTAGRAM"
    static let teamID = "35KLMK53PN"                   // seule signature acceptée pour une mise à jour
    private let interval: TimeInterval = 24 * 3600

    private(set) var state: State = .idle { didSet { onChange?() } }
    var onChange: (() -> Void)?
    private var assetURL: URL?
    private var checking = false
    private var timer: Timer?

    var currentVersion: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0" }
    var autoUpdate: Bool {
        get { UserDefaults.standard.object(forKey: "autoUpdate") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "autoUpdate") }
    }

    /// Une recherche par jour (au lancement puis toutes les heures), installation automatique si activée.
    func start() {
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in Task { @MainActor in Updater.shared.tick() } }
    }

    func tick() {
        guard autoUpdate else { return }
        let last = UserDefaults.standard.object(forKey: "updateLastCheck") as? Date ?? .distantPast
        if state == .idle || state == .upToDate, Date().timeIntervalSince(last) > interval { Task { await check() } }
        if case .available = state { Task { await install() } }
    }

    func check() async {
        guard !checking, state != .downloading else { return }
        checking = true; state = .checking
        defer { checking = false }
        do {
            var req = URLRequest(url: URL(string: "https://api.github.com/repos/\(Self.repo)/releases/latest")!)
            req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            req.timeoutInterval = 20
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String else { throw UpdateError.noRelease }
            UserDefaults.standard.set(Date(), forKey: "updateLastCheck")
            let assets = json["assets"] as? [[String: Any]] ?? []
            let zip = assets.first { ($0["name"] as? String)?.hasSuffix(".zip") == true }
            guard VersionCompare.isNewer(tag, than: currentVersion) else { state = .upToDate; return }
            guard let s = zip?["browser_download_url"] as? String, let url = URL(string: s) else { throw UpdateError.noRelease }
            assetURL = url
            state = .available(version: tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV")))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Télécharge la nouvelle version, vérifie sa signature, puis remplace l'appli et la relance.
    func install() async {
        guard case .available = state, let url = assetURL else { return }
        state = .downloading
        do {
            let work = FileManager.default.temporaryDirectory.appendingPathComponent("mSTAGRAM-update-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
            let (tmp, resp) = try await URLSession.shared.download(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw UpdateError.download }
            let zip = work.appendingPathComponent("update.zip")
            try FileManager.default.moveItem(at: tmp, to: zip)
            let out = work.appendingPathComponent("out")
            try await Self.run("/usr/bin/ditto", ["-x", "-k", zip.path, out.path])
            let app = out.appendingPathComponent("mSTAGRAM.app")
            try await Self.verify(app)
            try Self.swapAndRelaunch(new: app, work: work)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    enum UpdateError: LocalizedError {
        case noRelease, download, badSignature, badVersion
        var errorDescription: String? {
            switch self {
            case .noRelease: return L10n.t("upd.err.none")
            case .download: return L10n.t("upd.err.download")
            case .badSignature: return L10n.t("upd.err.signature")
            case .badVersion: return L10n.t("upd.err.version")
            }
        }
    }

    /// La nouvelle appli doit être valide, signée par la même équipe et plus récente.
    private static func verify(_ app: URL) async throws {
        try await run("/usr/bin/codesign", ["--verify", "--deep", "--strict", app.path])
        let info = try await run("/usr/bin/codesign", ["-dv", "--verbose=2", app.path])
        guard info.contains("TeamIdentifier=\(teamID)") else { throw UpdateError.badSignature }
        guard let plist = NSDictionary(contentsOf: app.appendingPathComponent("Contents/Info.plist")),
              plist["CFBundleIdentifier"] as? String == Bundle.main.bundleIdentifier,
              let v = plist["CFBundleShortVersionString"] as? String,
              VersionCompare.isNewer(v, than: Updater.shared.currentVersion) else { throw UpdateError.badVersion }
    }

    /// Un petit script détaché attend la fin de l'appli, remplace le paquet puis relance la nouvelle version.
    private static func swapAndRelaunch(new: URL, work: URL) throws {
        let target = Bundle.main.bundlePath
        let script = work.appendingPathComponent("swap.sh")
        let body = """
        #!/bin/sh
        while kill -0 \(ProcessInfo.processInfo.processIdentifier) 2>/dev/null; do sleep 0.3; done
        rm -rf "\(target)" && /usr/bin/ditto "\(new.path)" "\(target)" && /usr/bin/open -g "\(target)"
        rm -rf "\(work.path)"
        """
        try body.write(to: script, atomically: true, encoding: .utf8)
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/sh")
        p.arguments = [script.path]
        p.standardOutput = FileHandle.nullDevice; p.standardError = FileHandle.nullDevice
        try p.run()
        NSApp.terminate(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { exit(0) }
    }

    @discardableResult
    private static func run(_ exe: String, _ args: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { cont in
            DispatchQueue.global().async {
                let p = Process(), pipe = Pipe()
                p.executableURL = URL(fileURLWithPath: exe); p.arguments = args
                p.standardOutput = pipe; p.standardError = pipe
                do { try p.run() } catch { cont.resume(throwing: error); return }
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                p.waitUntilExit()
                let text = String(decoding: data, as: UTF8.self)
                if p.terminationStatus == 0 { cont.resume(returning: text) }
                else { cont.resume(throwing: exe.hasSuffix("codesign") ? UpdateError.badSignature : UpdateError.download) }
            }
        }
    }
}

enum VersionCompare {
    static func isNewer(_ a: String, than b: String) -> Bool {
        func parts(_ s: String) -> [Int] { s.trimmingCharacters(in: CharacterSet(charactersIn: "vV")).split(separator: ".").map { Int($0) ?? 0 } }
        let x = parts(a), y = parts(b)
        for i in 0..<max(x.count, y.count) {
            let p = i < x.count ? x[i] : 0, q = i < y.count ? y[i] : 0
            if p != q { return p > q }
        }
        return false
    }
}

// MARK: - Fenêtre de réglages : mise à jour automatique + bouton manuel
@MainActor
final class UpdateWindow: NSObject {
    static let shared = UpdateWindow()
    private var window: NSWindow?
    private let status = NSTextField(wrappingLabelWithString: "")
    private let auto = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let check = NSButton(title: "", target: nil, action: nil)
    private let install = NSButton(title: "", target: nil, action: nil)

    func show() {
        if window == nil { build() }
        refresh()
        window?.center(); window?.makeKeyAndOrderFront(nil)
    }

    private func build() {
        let u = Updater.shared
        auto.title = L10n.t("upd.auto"); auto.target = self; auto.action = #selector(toggleAuto)
        check.title = L10n.t("upd.check"); check.target = self; check.action = #selector(doCheck); check.bezelStyle = .rounded
        install.target = self; install.action = #selector(doInstall); install.bezelStyle = .rounded; install.keyEquivalent = "\r"
        status.textColor = .secondaryLabelColor; status.font = .systemFont(ofSize: 12)
        let buttons = NSStackView(views: [check, install]); buttons.orientation = .horizontal; buttons.spacing = 10
        let stack = NSStackView(views: [auto, buttons, status])
        stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.widthAnchor.constraint(equalToConstant: 420).isActive = true
        status.preferredMaxLayoutWidth = 370
        let w = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = L10n.t("upd.title"); w.isReleasedWhenClosed = false
        let content = NSView(); content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor), stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor), stack.bottomAnchor.constraint(equalTo: content.bottomAnchor)])
        w.contentView = content
        window = w
        u.onChange = { [weak self] in self?.refresh() }
    }

    func refresh() {
        let u = Updater.shared
        auto.state = u.autoUpdate ? .on : .off
        install.isHidden = true
        switch u.state {
        case .idle: status.stringValue = L10n.t("upd.version", u.currentVersion)
        case .checking: status.stringValue = L10n.t("upd.checking")
        case .upToDate: status.stringValue = L10n.t("upd.uptodate", u.currentVersion)
        case .available(let v): status.stringValue = L10n.t("upd.available", v); install.title = L10n.t("upd.install", v); install.isHidden = false
        case .downloading: status.stringValue = L10n.t("upd.downloading")
        case .failed(let e): status.stringValue = L10n.t("upd.failed", e)
        }
        check.isEnabled = u.state != .checking && u.state != .downloading
    }

    @objc private func toggleAuto() { Updater.shared.autoUpdate = auto.state == .on }
    @objc private func doCheck() { Task { await Updater.shared.check() } }
    @objc private func doInstall() { Task { await Updater.shared.install() } }
}

enum UpdStrings {
    static let table: [String: [String: String]] = [
        "fr": ["upd.title": "Mise à jour", "upd.auto": "Installer automatiquement les mises à jour", "upd.check": "Rechercher une mise à jour",
               "upd.install": "Installer la version %@", "upd.version": "Version installée : %@", "upd.checking": "Recherche en cours…",
               "upd.uptodate": "mSTAGRAM est à jour (version %@).", "upd.available": "La version %@ est disponible.",
               "upd.downloading": "Téléchargement et installation…", "upd.failed": "Échec de la mise à jour : %@",
               "upd.err.none": "Aucune version téléchargeable trouvée.", "upd.err.download": "Le téléchargement a échoué.",
               "upd.err.signature": "La signature de la mise à jour n'est pas valide.", "upd.err.version": "La mise à jour n'est pas une version plus récente de l'appli.",
               "menu.update": "Rechercher les mises à jour…"],
        "en": ["upd.title": "Update", "upd.auto": "Install updates automatically", "upd.check": "Check for updates",
               "upd.install": "Install version %@", "upd.version": "Installed version: %@", "upd.checking": "Checking…",
               "upd.uptodate": "mSTAGRAM is up to date (version %@).", "upd.available": "Version %@ is available.",
               "upd.downloading": "Downloading and installing…", "upd.failed": "Update failed: %@",
               "upd.err.none": "No downloadable release found.", "upd.err.download": "The download failed.",
               "upd.err.signature": "The update's signature is not valid.", "upd.err.version": "The update is not a newer version of the app.",
               "menu.update": "Check for Updates…"],
        "es": ["upd.title": "Actualización", "upd.auto": "Instalar las actualizaciones automáticamente", "upd.check": "Buscar actualizaciones",
               "upd.install": "Instalar la versión %@", "upd.version": "Versión instalada: %@", "upd.checking": "Buscando…",
               "upd.uptodate": "mSTAGRAM está actualizado (versión %@).", "upd.available": "La versión %@ está disponible.",
               "upd.downloading": "Descargando e instalando…", "upd.failed": "Error de actualización: %@",
               "upd.err.none": "No se encontró ninguna versión descargable.", "upd.err.download": "La descarga ha fallado.",
               "upd.err.signature": "La firma de la actualización no es válida.", "upd.err.version": "La actualización no es una versión más reciente de la app.",
               "menu.update": "Buscar actualizaciones…"],
        "it": ["upd.title": "Aggiornamento", "upd.auto": "Installa automaticamente gli aggiornamenti", "upd.check": "Cerca aggiornamenti",
               "upd.install": "Installa la versione %@", "upd.version": "Versione installata: %@", "upd.checking": "Ricerca in corso…",
               "upd.uptodate": "mSTAGRAM è aggiornato (versione %@).", "upd.available": "La versione %@ è disponibile.",
               "upd.downloading": "Download e installazione…", "upd.failed": "Aggiornamento non riuscito: %@",
               "upd.err.none": "Nessuna versione scaricabile trovata.", "upd.err.download": "Il download non è riuscito.",
               "upd.err.signature": "La firma dell'aggiornamento non è valida.", "upd.err.version": "L'aggiornamento non è una versione più recente dell'app.",
               "menu.update": "Cerca aggiornamenti…"]
    ]
}
