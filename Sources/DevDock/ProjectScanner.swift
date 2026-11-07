import Foundation

/// Finds every git repository under a root folder, nested repositories included.
struct ProjectScanner {
    let root: URL

    private let maxDepth = 4
    private let ignoredFolders: Set<String> = ["node_modules", "vendor", ".build", "tmp"]

    func scan() -> [Project] {
        var projects: [Project] = []
        visit(root, depth: 0, into: &projects)

        return projects.sorted {
            $0.relativePath.localizedStandardCompare($1.relativePath) == .orderedAscending
        }
    }

    private func visit(_ folder: URL, depth: Int, into projects: inout [Project]) {
        let children = (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey]
        )) ?? []

        if children.contains(where: { $0.lastPathComponent == ".git" }) {
            projects.append(project(at: folder))
        }

        guard depth < maxDepth else { return }

        for child in children where isTraversable(child) {
            visit(child, depth: depth + 1, into: &projects)
        }
    }

    private func isTraversable(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        guard !name.hasPrefix("."), !ignoredFolders.contains(name) else { return false }

        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        return values?.isDirectory == true && values?.isSymbolicLink != true
    }

    private func project(at folder: URL) -> Project {
        let relativePath = String(folder.path.dropFirst(root.path.count + 1))
        return Project(url: folder, relativePath: relativePath)
    }
}
