import SwiftUI

struct ClipboardView: View {
    @ObservedObject var clipboardStore: ClipboardStore
    @ObservedObject var snippetStore: SnippetStore
    @State private var isAddingSnippet = false
    @State private var newSnippetName = ""
    @State private var newSnippetContent = ""

    private var canSaveSnippet: Bool {
        !newSnippetName.isEmpty && !newSnippetContent.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    sectionTitle("Snippets")

                    Spacer()

                    Button(isAddingSnippet ? "Annuler" : "Nouveau snippet") {
                        isAddingSnippet.toggle()
                    }
                    .controlSize(.small)
                }

                if isAddingSnippet {
                    newSnippetForm
                }

                ForEach(snippetStore.snippets) { snippet in
                    HStack {
                        CopyableTextRow(title: snippet.name, text: snippet.content) {
                            clipboardStore.copy(snippet.content)
                        }

                        Button {
                            snippetStore.delete(snippet)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Supprimer le snippet")
                    }
                }

                Divider()

                sectionTitle("Historique")

                if clipboardStore.history.isEmpty {
                    Text("Les textes copiés apparaîtront ici.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(clipboardStore.history, id: \.self) { text in
                    CopyableTextRow(title: nil, text: text) {
                        clipboardStore.copy(text)
                    }
                }
            }
        }
        .frame(height: 400)
    }

    private var newSnippetForm: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Nom", text: $newSnippetName)
            TextField("Contenu", text: $newSnippetContent, axis: .vertical)
                .lineLimit(3...6)

            Button("Enregistrer") {
                snippetStore.add(name: newSnippetName, content: newSnippetContent)
                newSnippetName = ""
                newSnippetContent = ""
                isAddingSnippet = false
            }
            .disabled(!canSaveSnippet)
        }
        .textFieldStyle(.roundedBorder)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

/// A clickable row that copies its text.
private struct CopyableTextRow: View {
    let title: String?
    let text: String
    let onCopy: () -> Void

    var body: some View {
        Button(action: onCopy) {
            VStack(alignment: .leading, spacing: 1) {
                if let title {
                    Text(title)
                        .fontWeight(.medium)
                }
                Text(text)
                    .font(title == nil ? .body : .caption)
                    .foregroundStyle(title == nil ? .primary : .secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Copier")
        .padding(.vertical, 3)
    }
}
