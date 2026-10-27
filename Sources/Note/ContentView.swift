import SwiftUI

struct ContentView: View {
    @Bindable var store: NotesStore
    @State private var titleDraft = ""
    @State private var bodyDraft = ""

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            editor
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 340)
        .onChange(of: store.selectedID) { _, _ in
            syncDraftsFromSelection()
        }
        .onAppear {
            syncDraftsFromSelection()
        }
    }

    private var sidebar: some View {
        List(selection: $store.selectedID) {
            ForEach(store.filteredNotes) { note in
                NoteRow(note: note)
                    .tag(note.id)
                    .contextMenu {
                        Button(note.isPinned ? "Unpin" : "Pin") {
                            store.togglePin(note)
                        }
                        Button("Delete", role: .destructive) {
                            store.delete(id: note.id)
                        }
                    }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $store.searchText, prompt: "Search notes")
        .navigationTitle("Notes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let note = store.createNote()
                    titleDraft = note.title
                    bodyDraft = note.body
                } label: {
                    Label("New Note", systemImage: "square.and.pencil")
                }
                .help("New note (⌘N)")
            }
        }
        .overlay {
            if store.filteredNotes.isEmpty {
                ContentUnavailableView {
                    Label(
                        store.notes.isEmpty ? "No notes yet" : "No matches",
                        systemImage: store.notes.isEmpty ? "note.text" : "magnifyingglass"
                    )
                } description: {
                    Text(store.notes.isEmpty ? "Write something new." : "Try a different search.")
                }
            }
        }
    }

    @ViewBuilder
    private var editor: some View {
        if store.selectedNote != nil {
            VStack(alignment: .leading, spacing: 0) {
                TextField("Title", text: $titleDraft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .padding(.horizontal, 36)
                    .padding(.top, 28)
                    .padding(.bottom, 12)
                    .onChange(of: titleDraft) { _, newValue in
                        store.updateSelected(title: newValue)
                    }

                TextEditor(text: $bodyDraft)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .lineSpacing(6)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                    .onChange(of: bodyDraft) { _, newValue in
                        store.updateSelected(body: newValue)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(nsColor: .textBackgroundColor))
            .toolbar {
                ToolbarItemGroup {
                    if let note = store.selectedNote {
                        Button {
                            store.togglePin(note)
                        } label: {
                            Label(
                                note.isPinned ? "Unpin" : "Pin",
                                systemImage: note.isPinned ? "pin.fill" : "pin"
                            )
                        }

                        Button(role: .destructive) {
                            store.deleteSelected()
                            syncDraftsFromSelection()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        } else {
            ContentUnavailableView("Select a note", systemImage: "square.and.pencil")
        }
    }

    private func syncDraftsFromSelection() {
        titleDraft = store.selectedNote?.title ?? ""
        bodyDraft = store.selectedNote?.body ?? ""
    }
}

private struct NoteRow: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(note.displayTitle)
                    .font(.headline)
                    .lineLimit(1)
            }
            Text(note.preview.isEmpty ? "Empty note" : note.preview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Text(note.updatedAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
