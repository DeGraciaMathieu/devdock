import Foundation

@MainActor
final class DiskUsageStore: ObservableObject {
    @Published private(set) var usages: [ProjectDiskUsage] = []
    @Published private(set) var isReading = false
    @Published private(set) var analyzedAt: Date?

    var totalBytes: Int64 { usages.reduce(0) { $0 + $1.totalBytes } }

    func analyze(_ projects: [Project]) {
        guard !isReading else { return }
        isReading = true

        Task {
            usages = await Task.detached { DiskUsageReader.read(projects) }.value
            analyzedAt = Date()
            isReading = false
        }
    }

    /// Moves the folder to the Trash, so a mistake can still be undone from Finder.
    func moveToTrash(_ folder: CleanableFolder) throws {
        try FileManager.default.trashItem(at: folder.url, resultingItemURL: nil)

        for index in usages.indices {
            usages[index].folders.removeAll { $0.id == folder.id }
        }
        usages.removeAll { $0.folders.isEmpty }
    }
}
