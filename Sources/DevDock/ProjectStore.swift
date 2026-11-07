import Foundation

@MainActor
final class ProjectStore: ObservableObject {
    @Published private(set) var projects: [Project] = []
    @Published private(set) var isScanning = false

    private let scanner = ProjectScanner(
        root: FileManager.default.homeDirectoryForCurrentUser.appending(path: "Sites")
    )

    init() {
        scan()
    }

    func scan() {
        guard !isScanning else { return }
        isScanning = true

        let scanner = self.scanner
        Task {
            // Walking ~/Sites takes a moment: keep it off the main thread.
            projects = await Task.detached { scanner.scan() }.value
            isScanning = false
        }
    }
}
