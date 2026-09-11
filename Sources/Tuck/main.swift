import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = MenuBarController()
    }
}

// `swift run Tuck --self-check` validates the pure logic without a menu bar.
if CommandLine.arguments.contains("--self-check") {
    selfCheck()
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
