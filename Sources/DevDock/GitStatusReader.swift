import Foundation

enum GitStatusReader {
    /// Reads the status of every project in parallel, keyed by project id.
    static func read(_ projects: [Project]) -> [String: GitStatus] {
        var statuses: [String: GitStatus] = [:]
        let lock = NSLock()

        DispatchQueue.concurrentPerform(iterations: projects.count) { index in
            let project = projects[index]
            guard let output = runGitStatus(in: project.url) else { return }

            let status = GitStatus(porcelain: output)
            lock.lock()
            statuses[project.id] = status
            lock.unlock()
        }

        return statuses
    }

    private static func runGitStatus(in folder: URL) -> String? {
        let git = Process()
        git.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        // --no-optional-locks: never take the index lock, so a git command running in a terminal is not disturbed.
        git.arguments = ["--no-optional-locks", "-C", folder.path, "status", "--porcelain=v2", "--branch"]

        let pipe = Pipe()
        git.standardOutput = pipe
        git.standardError = FileHandle.nullDevice

        do {
            try git.run()
        } catch {
            return nil
        }

        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        git.waitUntilExit()

        guard git.terminationStatus == 0 else { return nil }
        return String(decoding: output, as: UTF8.self)
    }
}
