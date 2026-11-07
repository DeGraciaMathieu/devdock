import SwiftUI

struct ProjectListView: View {
    @ObservedObject var store: ProjectStore
    @Binding var query: String

    private var filteredProjects: [Project] {
        guard !query.isEmpty else { return store.projects }
        return store.projects.filter { $0.relativePath.localizedCaseInsensitiveContains(query) }
    }

    private var favoriteProjects: [Project] {
        filteredProjects.filter { store.isFavorite($0) }
    }

    private var otherProjects: [Project] {
        filteredProjects.filter { !store.isFavorite($0) }
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
                    if !favoriteProjects.isEmpty {
                        sectionTitle("Favoris")
                        rows(for: favoriteProjects)

                        sectionTitle("Tous les projets")
                    }

                    rows(for: otherProjects)
                }
            }
            .frame(height: 380)

            Text(store.isScanning ? "Analyse de ~/Sites…" : "\(filteredProjects.count) projets")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func rows(for projects: [Project]) -> some View {
        ForEach(projects) { project in
            ProjectRowView(project: project, isFavorite: store.isFavorite(project)) {
                store.toggleFavorite(project)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }
}

private struct ProjectRowView: View {
    let project: Project
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.borderless)
            .help(isFavorite ? "Retirer des favoris" : "Ajouter aux favoris")

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
