import SwiftUI
import SwiftData

@main
struct GradebookAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Student.self,
            SchoolYear.self,
            Subject.self,
            Assignment.self,
            Book.self,
            Activity.self,
            FieldTrip.self,
            Course.self
        ])
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Student") {
                    // Action for new student
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}
