import Foundation

struct Snippet: Identifiable, Codable {
    var id = UUID()
    let name: String
    let content: String
}
