import SwiftUI

struct GitStatusListView: View {
    @ObservedObject var projectStore: ProjectStore
    @ObservedObject var gitStore: GitStatusStore
    @State private var showsAllProjects = false

    private var rows: [(project: Project, status: GitStatus)] {
        projectStore.projects.compactMap { project in
            guard let status = gitStore.statuses[project.id],
                  showsAllProjects || status.needsAttention else { return nil }

            return (project, status)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle("Afficher tous les projets", isOn: $showsAllProjects)

                Spacer()

                Button {
                    gitStore.refresh(projectStore.projects)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(gitStore.isReading || projectStore.isScanning)
                .help("Relire l'état git")
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(rows, id: \.project.id) { row in
                        GitStatusRowView(project: row.project, status: row.status)
                    }
                }
            }
            .frame(height: 380)

            Text(gitStore.isReading ? "Lecture de l'état git…" : "\(rows.count) projets")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        // Reads the statuses once the project scan is done, and again after each rescan.
        .task(id: projectStore.isScanning) {
            if !projectStore.isScanning {
                gitStore.refresh(projectStore.projects)
            }
        }
    }
}

private struct GitStatusRowView: View {
    let project: Project
    let status: GitStatus

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

            VStack(alignment: .trailing, spacing: 1) {
                Text(status.branch)
                    .font(.caption.monospaced())
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if status.changedFiles > 0 {
                        Text("\(status.changedFiles) modifié\(status.changedFiles > 1 ? "s" : "")")
                            .foregroundStyle(.orange)
                    }
                    if status.ahead > 0 {
                        Text("↑\(status.ahead)")
                            .foregroundStyle(.blue)
                    }
                    if status.behind > 0 {
                        Text("↓\(status.behind)")
                    }
                    if !status.needsAttention && status.behind == 0 {
                        Text("à jour")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
                .monospacedDigit()
            }
        }
        .padding(.vertical, 3)
    }
}
