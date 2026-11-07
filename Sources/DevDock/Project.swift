import Foundation

struct Project: Identifiable {
    let url: URL
    /// Path from the scanned root, e.g. `Labs/caquelon/filant`.
    let relativePath: String

    var id: String { url.path }
    var name: String { url.lastPathComponent }
}
