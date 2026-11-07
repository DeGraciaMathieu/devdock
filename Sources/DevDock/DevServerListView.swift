import SwiftUI

struct DevServerListView: View {
    @ObservedObject var projectStore: ProjectStore
    @ObservedObject var serverStore: DevServerStore
    @State private var showsAllProcesses = false
    @State private var pidPendingStop: Int32?
    @State private var errorMessage: String?

    private let refreshInterval: Duration = .seconds(3)

    private var visibleServers: [DevServer] {
        serverStore.servers.filter { showsAllProcesses || $0.project != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Afficher tous les processus", isOn: $showsAllProcesses)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(visibleServers) { server in
                        DevServerRowView(server: server, isPendingStop: pidPendingStop == server.pid) {
                            pidPendingStop = server.pid
                            errorMessage = nil
                        } onConfirmStop: {
                            stop(server)
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

            Text(visibleServers.isEmpty ? "Aucun serveur lancé depuis ~/Sites" : "\(visibleServers.count) serveurs")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        // Keeps the list live while the tab is shown; the loop stops when it is hidden.
        .task {
            while !Task.isCancelled {
                serverStore.refresh(projectStore.projects)
                try? await Task.sleep(for: refreshInterval)
            }
        }
    }

    private func stop(_ server: DevServer) {
        pidPendingStop = nil

        if kill(server.pid, SIGTERM) != 0 {
            let reason = String(cString: strerror(errno))
            errorMessage = "Impossible d'arrêter \(server.command) : \(reason)"
        }

        serverStore.refresh(projectStore.projects)
    }
}

private struct DevServerRowView: View {
    let server: DevServer
    let isPendingStop: Bool
    let onStop: () -> Void
    let onConfirmStop: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(server.command) · \(server.pid)")
                    .fontWeight(.medium)
                Text(server.project?.relativePath ?? server.workingDirectory ?? "dossier inconnu")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .truncationMode(.middle)

            Spacer()

            Text(String(format: "%.2f", locale: Locale(identifier: "fr_FR"), server.cores))
                .font(.caption)
                .monospacedDigit()
                .help("Cœurs utilisés")

            ForEach(server.ports, id: \.self) { port in
                Button(String(port)) {
                    NSWorkspace.shared.open(URL(string: "http://localhost:\(port)")!)
                }
                .controlSize(.small)
                .help("Ouvrir http://localhost:\(port)")
            }

            if isPendingStop {
                Button("Confirmer", action: onConfirmStop)
                    .controlSize(.small)
                    .tint(.red)
            } else {
                Button("Arrêter", action: onStop)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 3)
    }
}
