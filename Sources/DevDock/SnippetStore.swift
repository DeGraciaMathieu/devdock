import Foundation

@MainActor
final class SnippetStore: ObservableObject {
    @Published private(set) var snippets: [Snippet] = []

    private let fileURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appending(path: "devdock/snippets.json")

    init() {
        load()
    }

    func add(name: String, content: String) {
        snippets.append(Snippet(name: name, content: content))
        save()
    }

    func delete(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        snippets = (try? JSONDecoder().decode([Snippet].self, from: data)) ?? []
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(snippets).write(to: fileURL, options: .atomic)
        } catch {
            NSLog("DevDock: unable to save snippets: \(error)")
        }
    }
}
