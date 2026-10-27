import SwiftUI

@main
struct NoteApp: App {
    @State private var store = NotesStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .frame(minWidth: 720, minHeight: 480)
        }
        .defaultSize(width: 980, height: 640)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    store.createNote()
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .textEditing) {
                Button("Delete Note") {
                    store.deleteSelected()
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(store.selectedID == nil)
            }
        }
    }
}
