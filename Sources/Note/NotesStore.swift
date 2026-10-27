import Foundation
import Observation

@Observable
@MainActor
final class NotesStore {
    var notes: [Note] = []
    var selectedID: Note.ID?
    var searchText = ""

    var selectedNote: Note? {
        notes.first { $0.id == selectedID }
    }

    var filteredNotes: [Note] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matching: [Note]
        if query.isEmpty {
            matching = notes
        } else {
            matching = notes.filter {
                $0.title.localizedCaseInsensitiveContains(query)
                    || $0.body.localizedCaseInsensitiveContains(query)
            }
        }
        return matching.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
            return $0.updatedAt > $1.updatedAt
        }
    }

    private var saveTask: Task<Void, Never>?
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let folder = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0].appendingPathComponent("Cursor_Project_1_Note", isDirectory: true)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            self.fileURL = folder.appendingPathComponent("notes.json")
        }
        load()
        if notes.isEmpty {
            let intro = Note(
                title: "Welcome",
                body: """
                This is your first note.

                Write freely — everything saves as you type. Use ⌘N for a new note, ⌘F to search, and ⌘⌫ to delete.
                """
            )
            notes = [intro]
            selectedID = intro.id
            persist()
        } else if selectedID == nil {
            selectedID = filteredNotes.first?.id
        }
    }

    @discardableResult
    func createNote() -> Note {
        let note = Note()
        notes.insert(note, at: 0)
        selectedID = note.id
        persist()
        return note
    }

    func updateSelected(title: String? = nil, body: String? = nil) {
        guard let selectedID, let index = notes.firstIndex(where: { $0.id == selectedID }) else { return }
        if let title { notes[index].title = title }
        if let body { notes[index].body = body }
        notes[index].updatedAt = .now
        scheduleSave()
    }

    func togglePin(_ note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].isPinned.toggle()
        notes[index].updatedAt = .now
        persist()
    }

    func deleteSelected() {
        guard let selectedID else { return }
        delete(id: selectedID)
    }

    func delete(id: Note.ID) {
        let visible = filteredNotes
        let nextID: Note.ID?
        if let position = visible.firstIndex(where: { $0.id == id }) {
            if position + 1 < visible.count {
                nextID = visible[position + 1].id
            } else if position > 0 {
                nextID = visible[position - 1].id
            } else {
                nextID = nil
            }
        } else {
            nextID = selectedID
        }

        notes.removeAll { $0.id == id }
        selectedID = notes.contains(where: { $0.id == nextID }) ? nextID : filteredNotes.first?.id
        persist()
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            persist()
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoded = try? JSONDecoder().decode([Note].self, from: data)
        notes = decoded ?? []
        selectedID = notes.sorted { $0.updatedAt > $1.updatedAt }.first?.id
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save notes: \(error)")
        }
    }
}
