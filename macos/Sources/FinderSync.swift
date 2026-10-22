import Cocoa
import FinderSync

@objc(CopyPathFinderSync)
final class CopyPathFinderSync: FIFinderSync {
    private var menuURLs: [URL] = []
    private var menuHistory: [String] = []
    private let historyKey = "recentAbsolutePaths"
    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems || menuKind == .contextualMenuForContainer else { return nil }
        let controller = FIFinderSyncController.default()
        let urls: [URL]
        if menuKind == .contextualMenuForContainer {
            urls = controller.targetedURL().map { [$0] } ?? []
        } else {
            urls = controller.selectedItemURLs() ?? []
        }
        guard !urls.isEmpty else { return nil }
        menuURLs = urls
        let menu = NSMenu()
        let item = NSMenuItem(title: "Copy Path", action: #selector(copyPath(_:)), keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        menuHistory = UserDefaults.standard.stringArray(forKey: historyKey) ?? []
        menu.addItem(historyMenu(title: "Recent Paths", action: #selector(copyRecentPath(_:))))
        menu.addItem(historyMenu(title: "Open Paths", action: #selector(openRecentPath(_:))))
        return menu
    }

    private func historyMenu(title: String, action: Selector) -> NSMenuItem {
        let recent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        if menuHistory.isEmpty {
            let empty = NSMenuItem(title: "최근 복사한 경로 없음", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            submenu.addItem(empty)
        }
        for (index, path) in menuHistory.enumerated() {
            let url = URL(fileURLWithPath: path)
            let parent = url.deletingLastPathComponent().path
            let prefix = parent.count > 32 ? String(parent.prefix(32)) + "…" : parent
            let name = url.lastPathComponent.isEmpty ? "/" : url.lastPathComponent
            let label = name.count > 48 ? String(name.prefix(30)) + "…" + String(name.suffix(14)) : name
            let entry = NSMenuItem(title: "\(label) — \(prefix)", action: action, keyEquivalent: "")
            entry.target = self
            entry.tag = index
            entry.toolTip = path
            submenu.addItem(entry)
        }
        recent.submenu = submenu
        return recent
    }

    @objc private func copyPath(_ sender: NSMenuItem) {
        guard !menuURLs.isEmpty else { return }
        let paths = menuURLs.map { $0.path }.joined(separator: "\n")
        if writeClipboard(paths) { remember(menuURLs.map { $0.path }) }
    }

    @objc private func copyRecentPath(_ sender: NSMenuItem) {
        // Finder transports the menu across processes; use its preserved tag,
        // rather than representedObject, to resolve the displayed snapshot.
        guard menuHistory.indices.contains(sender.tag) else { return }
        let path = menuHistory[sender.tag]
        if writeClipboard(path) { remember([path]) }
    }

    private func writeClipboard(_ text: String) -> Bool {
        NSPasteboard.general.clearContents()
        return NSPasteboard.general.setString(text, forType: .string)
    }

    @objc private func openRecentPath(_ sender: NSMenuItem) {
        guard menuHistory.indices.contains(sender.tag) else { return }
        var request = URLComponents()
        request.scheme = "uengine-copy-path"
        request.host = "open"
        request.queryItems = [URLQueryItem(name: "path", value: menuHistory[sender.tag])]
        if let url = request.url { NSWorkspace.shared.open(url) }
    }

    private func remember(_ paths: [String]) {
        let previous = UserDefaults.standard.stringArray(forKey: historyKey) ?? []
        var seen = Set<String>()
        let history = (paths + previous).filter { seen.insert($0).inserted }
        UserDefaults.standard.set(Array(history.prefix(10)), forKey: historyKey)
    }
}
