import Foundation

@MainActor
final class DevServerStore: ObservableObject {
    @Published private(set) var servers: [DevServer] = []
    @Published private(set) var isReading = false

    func refresh(_ projects: [Project]) {
        guard !isReading else { return }
        isReading = true

        Task {
            servers = await Task.detached { DevServerReader.read(projects) }.value
            isReading = false
        }
    }
}
