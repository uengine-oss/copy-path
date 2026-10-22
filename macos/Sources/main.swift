import Cocoa
import FinderSync

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var status: NSTextField!
    private var openedPath = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            if !openedPath { showSettings() }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            guard url.scheme == "uengine-copy-path", url.host == "open",
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let path = components.queryItems?.first(where: { $0.name == "path" })?.value,
                  path.hasPrefix("/"), !path.contains("\0") else { continue }
            openedPath = true
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
        if openedPath && window == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { NSApp.terminate(nil) }
        }
    }

    private func showSettings() {
        NSApp.setActivationPolicy(.regular)
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 190),
                          styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Copy Path"
        window.center()
        let title = NSTextField(labelWithString: "우클릭 → Copy Path")
        title.font = .boldSystemFont(ofSize: 22)
        title.frame = NSRect(x: 28, y: 132, width: 390, height: 32)
        window.contentView?.addSubview(title)
        let detail = NSTextField(labelWithString: "절대경로 복사 · 최근 경로 다시 복사 / 열기 · 알림 없음")
        detail.frame = NSRect(x: 28, y: 98, width: 400, height: 24)
        window.contentView?.addSubview(detail)
        status = NSTextField(labelWithString: "")
        status.frame = NSRect(x: 28, y: 65, width: 400, height: 24)
        window.contentView?.addSubview(status)
        let button = NSButton(title: "Finder 확장 설정", target: self, action: #selector(openSettings))
        button.bezelStyle = .rounded
        button.frame = NSRect(x: 25, y: 20, width: 150, height: 32)
        window.contentView?.addSubview(button)
        refreshStatus()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationDidBecomeActive(_ notification: Notification) { refreshStatus() }
    func refreshStatus() {
        status?.stringValue = FIFinderSyncController.isExtensionEnabled
            ? "활성화됨 · 이 창을 닫아도 계속 사용할 수 있습니다."
            : "Finder 확장 설정에서 Copy Path를 켜 주세요."
    }
    @objc func openSettings() { FIFinderSyncController.showExtensionManagementInterface() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
