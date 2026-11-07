import SwiftUI

struct ContentView: View {
    @ObservedObject var projectStore: ProjectStore
    @ObservedObject var gitStore: GitStatusStore
    @ObservedObject var serverStore: DevServerStore
    @ObservedObject var clipboardStore: ClipboardStore
    @ObservedObject var snippetStore: SnippetStore
    @ObservedObject var diskStore: DiskUsageStore
    @State private var tab = Tab.projects
    /// Shared by the Projects, Git and Disk tabs, so switching tab keeps the search.
    @State private var projectQuery = ""

    private enum Tab {
        case projects
        case git
        case servers
        case clipboard
        case disk
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Onglet", selection: $tab) {
                Text("Projets").tag(Tab.projects)
                Text("Git").tag(Tab.git)
                Text("Serveurs").tag(Tab.servers)
                Text("Presse-papier").tag(Tab.clipboard)
                Text("Disque").tag(Tab.disk)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch tab {
            case .projects:
                ProjectListView(store: projectStore, query: $projectQuery)
            case .git:
                GitStatusListView(projectStore: projectStore, gitStore: gitStore, query: $projectQuery)
            case .servers:
                DevServerListView(projectStore: projectStore, serverStore: serverStore)
            case .clipboard:
                ClipboardView(clipboardStore: clipboardStore, snippetStore: snippetStore)
            case .disk:
                DiskUsageListView(projectStore: projectStore, diskStore: diskStore, query: $projectQuery)
            }

            Divider()

            HStack {
                Spacer()

                Button("Quitter DevDock") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(12)
        .frame(width: 480)
    }
}
