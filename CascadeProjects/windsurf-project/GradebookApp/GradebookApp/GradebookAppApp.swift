import SwiftUI
import SwiftData
import AppKit

@main
struct GradebookAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var backupManager = BackupManager()
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(backupManager)
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
        ], inMemory: false, isAutosaveEnabled: true, isUndoEnabled: false)
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
    // iCloud sync is automatic - no need for manual save on quit
    func applicationWillTerminate(_ notification: Notification) {
        // SwiftData with CloudKit handles sync automatically
    }
}
