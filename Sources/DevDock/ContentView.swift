import SwiftUI

struct ContentView: View {
    @ObservedObject var projectStore: ProjectStore
    @ObservedObject var gitStore: GitStatusStore
    @ObservedObject var serverStore: DevServerStore
    @ObservedObject var clipboardStore: ClipboardStore
    @ObservedObject var snippetStore: SnippetStore
    @State private var tab = Tab.projects

    private enum Tab {
        case projects
        case git
        case servers
        case clipboard
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Onglet", selection: $tab) {
                Text("Projets").tag(Tab.projects)
                Text("Git").tag(Tab.git)
                Text("Serveurs").tag(Tab.servers)
                Text("Presse-papier").tag(Tab.clipboard)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch tab {
            case .projects:
                ProjectListView(store: projectStore)
            case .git:
                GitStatusListView(projectStore: projectStore, gitStore: gitStore)
            case .servers:
                DevServerListView(projectStore: projectStore, serverStore: serverStore)
            case .clipboard:
                ClipboardView(clipboardStore: clipboardStore, snippetStore: snippetStore)
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
