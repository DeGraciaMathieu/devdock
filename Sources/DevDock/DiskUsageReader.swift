import Foundation

enum DiskUsageReader {
    private static let cleanableFolderNames = ["node_modules", "vendor", ".build", "storage/logs"]

    /// Measures the cleanable folders of every project in parallel, biggest projects first.
    static func read(_ projects: [Project]) -> [ProjectDiskUsage] {
        var usages: [ProjectDiskUsage] = []
        let lock = NSLock()

        DispatchQueue.concurrentPerform(iterations: projects.count) { index in
            let project = projects[index]
            let folders = cleanableFolders(of: project)
            guard !folders.isEmpty else { return }

            lock.lock()
            usages.append(ProjectDiskUsage(project: project, folders: folders))
            lock.unlock()
        }

        return usages.sorted { $0.totalBytes > $1.totalBytes }
    }

    private static func cleanableFolders(of project: Project) -> [CleanableFolder] {
        let existingFolders = cleanableFolderNames
            .map { project.url.appending(path: $0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
        guard !existingFolders.isEmpty else { return [] }

        let sizes = allocatedKilobytes(of: existingFolders)

        return existingFolders.compactMap { url in
            guard let kilobytes = sizes[url.path] else { return nil }

            let name = String(url.path.dropFirst(project.url.path.count + 1))
            return CleanableFolder(url: url, name: name, bytes: kilobytes * 1024)
        }
        .sorted { $0.bytes > $1.bytes }
    }

    /// Space really used on disk, as `du` reports it, keyed by folder path.
    private static func allocatedKilobytes(of folders: [URL]) -> [String: Int64] {
        let du = Process()
        du.executableURL = URL(fileURLWithPath: "/usr/bin/du")
        du.arguments = ["-sk"] + folders.map(\.path)

        let pipe = Pipe()
        du.standardOutput = pipe
        du.standardError = FileHandle.nullDevice

        do {
            try du.run()
        } catch {
            return [:]
        }

        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        du.waitUntilExit()

        var sizes: [String: Int64] = [:]

        // "812345\t/Users/me/Sites/blog/node_modules"
        for line in String(decoding: output, as: UTF8.self).split(separator: "\n") {
            let fields = line.split(separator: "\t", maxSplits: 1)
            guard fields.count == 2, let kilobytes = Int64(fields[0]) else { continue }

            sizes[String(fields[1])] = kilobytes
        }

        return sizes
    }
}
