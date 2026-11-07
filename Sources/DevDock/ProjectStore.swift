import Foundation

@MainActor
final class ProjectStore: ObservableObject {
    @Published private(set) var projects: [Project] = []
    @Published private(set) var isScanning = false
    /// Paths of the favorite projects, kept in the app preferences.
    @Published private(set) var favoriteIds: Set<String>

    private let favoritesKey = "favoriteProjectPaths"

    private let scanner = ProjectScanner(
        root: FileManager.default.homeDirectoryForCurrentUser.appending(path: "Sites")
    )

    init() {
        favoriteIds = Set(UserDefaults.standard.stringArray(forKey: favoritesKey) ?? [])
        scan()
    }

    func isFavorite(_ project: Project) -> Bool {
        favoriteIds.contains(project.id)
    }

    func toggleFavorite(_ project: Project) {
        if isFavorite(project) {
            favoriteIds.remove(project.id)
        } else {
            favoriteIds.insert(project.id)
        }

        UserDefaults.standard.set(Array(favoriteIds), forKey: favoritesKey)
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
