import SwiftUI

struct ProjectListView: View {
    @ObservedObject var store: ProjectStore
    @Binding var query: String

    private var filteredProjects: [Project] {
        guard !query.isEmpty else { return store.projects }
        return store.projects.filter { $0.relativePath.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Rechercher un projet", text: $query)
                    .textFieldStyle(.roundedBorder)

                Button {
                    store.scan()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(store.isScanning)
                .help("Analyser à nouveau ~/Sites")
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(filteredProjects) { project in
                        ProjectRowView(project: project)
                    }
                }
            }
            .frame(height: 380)

            Text(store.isScanning ? "Analyse de ~/Sites…" : "\(filteredProjects.count) projets")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ProjectRowView: View {
    let project: Project

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(project.name)
                    .fontWeight(.medium)
                Text(project.relativePath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .truncationMode(.middle)

            Spacer()

            ForEach(ProjectOpener.allCases, id: \.self) { opener in
                Button(opener.title) {
                    opener.open(project)
                }
                .controlSize(.small)
            }
        }
        .padding(.vertical, 3)
    }
}
