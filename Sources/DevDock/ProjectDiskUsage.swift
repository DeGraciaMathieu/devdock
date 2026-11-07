import Foundation

/// A folder that can be regenerated (dependencies, build output, logs), so it is safe to clean.
struct CleanableFolder: Identifiable {
    let url: URL
    /// Path from the project, e.g. `storage/logs`.
    let name: String
    let bytes: Int64

    var id: String { url.path }
}

struct ProjectDiskUsage: Identifiable {
    let project: Project
    var folders: [CleanableFolder]

    var id: String { project.id }
    var totalBytes: Int64 { folders.reduce(0) { $0 + $1.bytes } }
}
