import Foundation

enum DevServerReader {
    static func read(_ projects: [Project]) -> [DevServer] {
        let portsByPid = listeningPorts()
        let pids = Array(portsByPid.keys)
        let workingDirectories = workingDirectories(of: pids)
        let coresByPid = coreUsage(of: pids)

        return portsByPid.map { pid, listener in
            let workingDirectory = workingDirectories[pid]

            return DevServer(
                pid: pid,
                command: listener.command,
                ports: listener.ports.sorted(),
                workingDirectory: workingDirectory,
                cores: coresByPid[pid] ?? 0,
                project: workingDirectory.flatMap { project(containing: $0, in: projects) }
            )
        }
        .sorted { $0.cores > $1.cores }
    }

    private static func listeningPorts() -> [Int32: (command: String, ports: Set<Int>)] {
        var listeners: [Int32: (command: String, ports: Set<Int>)] = [:]
        var currentPid: Int32?

        // `-F` prints one field per line, prefixed by its type: p = pid, c = command, n = address.
        for field in run("/usr/sbin/lsof", ["+c", "0", "-nP", "-iTCP", "-sTCP:LISTEN", "-Fpcn"]) {
            let value = String(field.dropFirst())

            switch field.first {
            case "p":
                currentPid = Int32(value)
            case "c":
                guard let pid = currentPid else { continue }
                // lsof escapes spaces in command names.
                listeners[pid] = (value.replacingOccurrences(of: "\\x20", with: " "), [])
            case "n":
                // "*:5173", "127.0.0.1:8000" or "[::1]:5173"
                guard let pid = currentPid, let port = value.split(separator: ":").last.flatMap({ Int($0) }) else { continue }
                listeners[pid]?.ports.insert(port)
            default:
                continue
            }
        }

        return listeners
    }

    private static func workingDirectories(of pids: [Int32]) -> [Int32: String] {
        guard !pids.isEmpty else { return [:] }

        let pidList = pids.map(String.init).joined(separator: ",")
        var directories: [Int32: String] = [:]
        var currentPid: Int32?

        for field in run("/usr/sbin/lsof", ["-a", "-d", "cwd", "-Fpn", "-p", pidList]) {
            let value = String(field.dropFirst())

            switch field.first {
            case "p":
                currentPid = Int32(value)
            case "n":
                if let pid = currentPid { directories[pid] = value }
            default:
                continue
            }
        }

        return directories
    }

    private static func coreUsage(of pids: [Int32]) -> [Int32: Double] {
        guard !pids.isEmpty else { return [:] }

        let pidList = pids.map(String.init).joined(separator: ",")
        var cores: [Int32: Double] = [:]

        for line in run("/bin/ps", ["-o", "pid=,pcpu=", "-p", pidList]) {
            let fields = line.split(separator: " ")
            guard fields.count == 2, let pid = Int32(fields[0]), let cpu = Double(fields[1]) else { continue }

            // ps reports a percentage of one core.
            cores[pid] = cpu / 100
        }

        return cores
    }

    /// The deepest project containing the folder, so a nested repository wins over its parent.
    private static func project(containing path: String, in projects: [Project]) -> Project? {
        projects
            .filter { path == $0.url.path || path.hasPrefix($0.url.path + "/") }
            .max { $0.url.path.count < $1.url.path.count }
    }

    private static func run(_ executable: String, _ arguments: [String]) -> [Substring] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        // Forces a dot as decimal separator in ps output whatever the user locale.
        process.environment = ["LC_ALL": "C"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return []
        }

        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return String(decoding: output, as: UTF8.self).split(separator: "\n")
    }
}
