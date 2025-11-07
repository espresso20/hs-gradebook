import SwiftUI
import SwiftData
import AppKit

@main
struct GradebookAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var cloudSaveManager = CloudSaveManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cloudSaveManager)
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

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        // Auto-save to cloud on quit
        Task {
            let cloudSaveManager = CloudSaveManager()
            if cloudSaveManager.credentialsConfigured {
                // Get model context from shared container
                if let container = try? ModelContainer(for: Student.self, SchoolYear.self, Subject.self, Assignment.self, Book.self, Activity.self, FieldTrip.self, Course.self) {
                    let context = ModelContext(container)
                    await cloudSaveManager.saveToCloud(modelContext: context)
                }
            }
        }
    }
}
