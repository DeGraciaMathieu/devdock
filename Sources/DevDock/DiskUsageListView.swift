import SwiftUI

struct DiskUsageListView: View {
    @ObservedObject var projectStore: ProjectStore
    @ObservedObject var diskStore: DiskUsageStore
    @Binding var query: String
    @State private var folderPendingTrash: String?
    @State private var errorMessage: String?

    private var visibleUsages: [ProjectDiskUsage] {
        guard !query.isEmpty else { return diskStore.usages }
        return diskStore.usages.filter { $0.project.relativePath.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Rechercher un projet", text: $query)
                    .textFieldStyle(.roundedBorder)

                Button("Analyser") {
                    diskStore.analyze(projectStore.projects)
                }
                .disabled(diskStore.isReading || projectStore.isScanning)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(visibleUsages) { usage in
                        DiskUsageRowView(usage: usage, folderPendingTrash: $folderPendingTrash) { folder in
                            moveToTrash(folder)
                        }
                    }
                }
            }
            .frame(height: 380)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Text(summary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var summary: String {
        if diskStore.isReading {
            return "Analyse de l'espace disque…"
        }
        guard let analyzedAt = diskStore.analyzedAt else {
            return "Pas encore analysé"
        }

        let total = ByteCountFormatter.string(fromByteCount: diskStore.totalBytes, countStyle: .file)
        let time = analyzedAt.formatted(date: .omitted, time: .shortened)
        return "\(total) récupérables · analysé à \(time)"
    }

    private func moveToTrash(_ folder: CleanableFolder) {
        folderPendingTrash = nil
        errorMessage = nil

        do {
            try diskStore.moveToTrash(folder)
        } catch {
            errorMessage = "Impossible de mettre \(folder.name) à la corbeille : \(error.localizedDescription)"
        }
    }
}

private struct DiskUsageRowView: View {
    let usage: ProjectDiskUsage
    @Binding var folderPendingTrash: String?
    let onConfirmTrash: (CleanableFolder) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(usage.project.name)
                        .fontWeight(.medium)
                    Text(usage.project.relativePath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
                .truncationMode(.middle)

                Spacer()

                Text(ByteCountFormatter.string(fromByteCount: usage.totalBytes, countStyle: .file))
                    .monospacedDigit()
            }

            HStack(spacing: 6) {
                ForEach(usage.folders) { folder in
                    folderButton(folder)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func folderButton(_ folder: CleanableFolder) -> some View {
        let label = "\(folder.name) · \(ByteCountFormatter.string(fromByteCount: folder.bytes, countStyle: .file))"

        if folderPendingTrash == folder.id {
            // Wider than the initial button, so a second click at the same place always confirms
            // instead of landing on the next button.
            Button("Corbeille ? \(label)") {
                onConfirmTrash(folder)
            }
            .controlSize(.small)
            .tint(.red)
        } else {
            Button(label) {
                folderPendingTrash = folder.id
            }
            .controlSize(.small)
            .help("Mettre \(folder.name) à la corbeille")
        }
    }
}
