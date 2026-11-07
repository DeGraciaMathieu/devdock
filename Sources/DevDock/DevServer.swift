import Foundation

/// A process listening on at least one TCP port.
struct DevServer: Identifiable {
    let pid: Int32
    let command: String
    let ports: [Int]
    let workingDirectory: String?
    /// CPU usage in cores: 1.0 means one full core.
    let cores: Double
    let project: Project?

    var id: Int32 { pid }
}
