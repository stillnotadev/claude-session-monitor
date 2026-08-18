import ServiceManagement

/// Registers/unregisters Headroom as a login item using macOS's native
/// ServiceManagement API — no manual step in System Settings needed.
/// Only works correctly when running from a proper, stable .app bundle
/// (i.e. built via build-app.sh, not `swift run`).
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Not critical enough to surface as an alert — System Settings
            // > Login Items still works as a manual fallback.
        }
    }
}
