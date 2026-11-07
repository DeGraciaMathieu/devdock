import Foundation

@MainActor
final class GitStatusStore: ObservableObject {
    @Published private(set) var statuses: [String: GitStatus] = [:]
    @Published private(set) var isReading = false

    func refresh(_ projects: [Project]) {
        guard !isReading else { return }
        isReading = true

        Task {
            statuses = await Task.detached { GitStatusReader.read(projects) }.value
            isReading = false
        }
    }
}
