import AppKit

enum ProjectOpener: CaseIterable {
    case cursor
    case iTerm
    case finder

    var title: String {
        switch self {
        case .cursor: "Cursor"
        case .iTerm: "iTerm"
        case .finder: "Finder"
        }
    }

    private var bundleIdentifier: String {
        switch self {
        case .cursor: "com.todesktop.230313mzl4w4u92"
        case .iTerm: "com.googlecode.iterm2"
        case .finder: "com.apple.finder"
        }
    }

    func open(_ project: Project) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else { return }

        NSWorkspace.shared.open([project.url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
    }
}
