import SwiftUI

@main
struct DevDockApp: App {
    @StateObject private var projectStore = ProjectStore()
    @StateObject private var gitStore = GitStatusStore()
    @StateObject private var serverStore = DevServerStore()
    // Created with the app, not lazily on first panel opening, so copies are recorded from launch.
    private let clipboardStore = ClipboardStore()
    @StateObject private var snippetStore = SnippetStore()
    @StateObject private var diskStore = DiskUsageStore()

    var body: some Scene {
        MenuBarExtra("DevDock", systemImage: "shippingbox") {
            ContentView(
                projectStore: projectStore,
                gitStore: gitStore,
                serverStore: serverStore,
                clipboardStore: clipboardStore,
                snippetStore: snippetStore,
                diskStore: diskStore
            )
        }
        .menuBarExtraStyle(.window)
    }
}
