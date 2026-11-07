struct GitStatus {
    private(set) var branch = "?"
    private(set) var changedFiles = 0
    private(set) var ahead = 0
    private(set) var behind = 0

    /// Uncommitted changes or commits not pushed yet.
    var needsAttention: Bool { changedFiles > 0 || ahead > 0 }

    /// Parses the output of `git status --porcelain=v2 --branch`.
    init(porcelain: String) {
        for line in porcelain.split(separator: "\n") {
            if line.hasPrefix("# branch.head ") {
                branch = String(line.dropFirst("# branch.head ".count))
            } else if line.hasPrefix("# branch.ab ") {
                // "# branch.ab +2 -5"
                let counts = line.split(separator: " ")
                ahead = Int(counts[2].dropFirst()) ?? 0
                behind = Int(counts[3].dropFirst()) ?? 0
            } else if !line.hasPrefix("#") {
                changedFiles += 1
            }
        }
    }
}
