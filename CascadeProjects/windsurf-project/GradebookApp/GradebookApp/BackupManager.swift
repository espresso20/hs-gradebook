import Foundation
import SwiftUI
import SwiftData
import CloudKit

// MARK: - Backup Manager
@MainActor
class BackupManager: ObservableObject {
    @Published var iCloudAvailable = false
    @Published var googleDriveConnected = false
    @Published var lastGoogleBackup: Date?
    @Published var isBackingUp = false
    @Published var backupError: String?
    @Published var selectedBackupMethod: BackupMethod = .none
    
    // Don't initialize CloudKit container without entitlements
    // This prevents crashes when iCloud capability is not configured
    private let hasCloudKitEntitlements = false // Set to true if you add iCloud entitlements
    
    init() {
        Task {
            await checkiCloudStatus()
        }
    }
    
    enum BackupMethod: String, CaseIterable {
        case none = "No Backup"
        case iCloud = "iCloud"
        case googleDrive = "Manual Export"
        
        var icon: String {
            switch self {
            case .none: return "xmark.circle"
            case .iCloud: return "icloud.fill"
            case .googleDrive: return "arrow.down.doc.fill"
            }
        }
        
        var description: String {
            switch self {
            case .none: return "Store data locally only"
            case .iCloud: return "Automatic sync across your Apple devices"
            case .googleDrive: return "Export JSON backups to save anywhere"
            }
        }
    }
    
    // MARK: - iCloud Status
    
    func checkiCloudStatus() async {
        // Don't try to access CloudKit without entitlements
        guard hasCloudKitEntitlements else {
            await MainActor.run {
                iCloudAvailable = false
            }
            return
        }
        
        do {
            let container = CKContainer.default()
            let status = try await container.accountStatus()
            await MainActor.run {
                iCloudAvailable = (status == .available)
            }
        } catch {
            await MainActor.run {
                iCloudAvailable = false
            }
        }
    }
    
    func getiCloudAccountInfo() async -> String? {
        guard iCloudAvailable, hasCloudKitEntitlements else { return nil }
        
        do {
            let container = CKContainer.default()
            // Try to get user record to check iCloud account
            let userRecordID = try await container.userRecordID()
            return userRecordID.recordName
        } catch {
            return nil
        }
    }
    
    // MARK: - Google Drive Backup
    
    func connectGoogleDrive() {
        // TODO: Implement Google OAuth with Google Sign-In SDK
        // For now, this just enables local JSON export
        googleDriveConnected = true
    }
    
    func disconnectGoogleDrive() {
        googleDriveConnected = false
        lastGoogleBackup = nil
    }
    
    func backupToGoogleDrive(modelContext: ModelContext) async {
        guard googleDriveConnected else {
            backupError = "Google Drive not connected"
            return
        }
        
        isBackingUp = true
        backupError = nil
        
        do {
            // Export data to JSON
            let jsonData = try await exportData(modelContext: modelContext)
            
            // Save to file with save panel
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.canCreateDirectories = true
            panel.isExtensionHidden = false
            panel.title = "Save Gradebook Backup"
            panel.message = "Choose where to save your backup file"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
            let dateString = dateFormatter.string(from: Date())
            panel.nameFieldStringValue = "gradebook-backup-\(dateString).json"
            
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    do {
                        try jsonData.write(to: url)
                        Task { @MainActor in
                            self.lastGoogleBackup = Date()
                            self.isBackingUp = false
                        }
                    } catch {
                        Task { @MainActor in
                            self.backupError = "Failed to save file: \(error.localizedDescription)"
                            self.isBackingUp = false
                        }
                    }
                } else {
                    Task { @MainActor in
                        self.backupError = "Backup cancelled"
                        self.isBackingUp = false
                    }
                }
            }
        } catch {
            await MainActor.run {
                backupError = "Export failed: \(error.localizedDescription)"
                isBackingUp = false
            }
        }
    }
    
    // MARK: - Data Import
    
    func importBackup(modelContext: ModelContext) async -> Bool {
        // Open file picker and wait for response
        let url: URL? = await withCheckedContinuation { continuation in
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.json]
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            panel.title = "Select Backup File"
            panel.message = "Choose a Gradebook backup JSON file to restore"
            
            panel.begin { response in
                if response == .OK, let selectedURL = panel.url {
                    continuation.resume(returning: selectedURL)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
        
        guard let fileURL = url else {
            await MainActor.run {
                self.backupError = "Import cancelled"
            }
            return false
        }
        
        // Perform the import
        return await performImport(from: fileURL, modelContext: modelContext)
    }
    
    private func performImport(from url: URL, modelContext: ModelContext) async -> Bool {
        await MainActor.run {
            isBackingUp = true
            backupError = nil
        }
        
        do {
            // First, create a backup of current data
            let backupData = try await exportData(modelContext: modelContext)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
            let dateString = dateFormatter.string(from: Date())
            
            // Save backup to Documents/GradebookBackups
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let backupsFolder = documentsURL.appendingPathComponent("GradebookBackups", isDirectory: true)
            
            // Create backups folder if needed
            try? FileManager.default.createDirectory(at: backupsFolder, withIntermediateDirectories: true)
            
            let autoBackupURL = backupsFolder.appendingPathComponent("pre-import-backup-\(dateString).json")
            try backupData.write(to: autoBackupURL)
            
            // Read the import file
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importedData = try decoder.decode(GradebookExport.self, from: jsonData)
            
            // Clear existing data
            try await clearAllData(modelContext: modelContext)
            
            // Import new data
            try await importData(importedData, into: modelContext)
            
            await MainActor.run {
                isBackingUp = false
                backupError = nil
            }
            
            return true
        } catch {
            await MainActor.run {
                backupError = "Import failed: \(error.localizedDescription)"
                isBackingUp = false
            }
            return false
        }
    }
    
    private func clearAllData(modelContext: ModelContext) async throws {
        // Fetch and delete all students (cascade will handle rest)
        let descriptor = FetchDescriptor<Student>()
        let students = try modelContext.fetch(descriptor)
        
        for student in students {
            modelContext.delete(student)
        }
        
        try modelContext.save()
    }
    
    private func importData(_ exportData: GradebookExport, into modelContext: ModelContext) async throws {
        for studentData in exportData.students {
            let student = Student(
                name: studentData.name,
                grade: studentData.gradeLevel,
                school: studentData.schoolName
            )
            student.id = studentData.id
            modelContext.insert(student)
            
            for yearData in studentData.schoolYears {
                let schoolYear = SchoolYear(
                    year: yearData.year,
                    startDate: yearData.startDate,
                    endDate: yearData.endDate,
                    totalSchoolDays: yearData.totalSchoolDays
                )
                schoolYear.id = yearData.id
                schoolYear.student = student
                modelContext.insert(schoolYear)
                
                // Import subjects
                for subjectData in yearData.subjects {
                    let subject = Subject(
                        name: subjectData.name,
                        credits: subjectData.credits,
                        color: subjectData.color,
                        order: subjectData.order
                    )
                    subject.id = subjectData.id
                    subject.dailyWeight = subjectData.dailyWeight
                    subject.quizWeight = subjectData.quizWeight
                    subject.testWeight = subjectData.testWeight
                    subject.projectWeight = subjectData.projectWeight
                    subject.otherWeight = subjectData.otherWeight
                    subject.schoolYear = schoolYear
                    modelContext.insert(subject)
                    
                    // Import assignments
                    for assignmentData in subjectData.assignments {
                        let assignment = Assignment(
                            title: assignmentData.name,
                            type: AssignmentType(rawValue: assignmentData.category) ?? .daily,
                            date: assignmentData.date,
                            score: assignmentData.score,
                            maxScore: assignmentData.maxScore,
                            notes: assignmentData.notes ?? ""
                        )
                        assignment.id = assignmentData.id
                        assignment.subject = subject
                        modelContext.insert(assignment)
                    }
                }
                
                // Import books
                for bookData in yearData.books {
                    let book = Book(
                        title: bookData.title,
                        author: bookData.author,
                        dateRead: bookData.dateRead,
                        notes: bookData.notes
                    )
                    book.id = bookData.id
                    book.schoolYear = schoolYear
                    modelContext.insert(book)
                }
                
                // Import activities
                for activityData in yearData.activities {
                    let activity = Activity(
                        date: activityData.date,
                        activityDescription: activityData.activityDescription,
                        role: activityData.role
                    )
                    activity.id = activityData.id
                    activity.schoolYear = schoolYear
                    modelContext.insert(activity)
                }
                
                // Import field trips
                for tripData in yearData.fieldTrips {
                    let trip = FieldTrip(
                        date: tripData.date,
                        tripDescription: tripData.tripDescription,
                        location: tripData.location,
                        notes: tripData.notes
                    )
                    trip.id = tripData.id
                    trip.schoolYear = schoolYear
                    modelContext.insert(trip)
                }
                
                // Import courses
                for courseData in yearData.courses {
                    let course = Course(
                        title: courseData.title,
                        courseDescription: courseData.courseDescription,
                        resources: courseData.resources
                    )
                    course.id = courseData.id
                    course.schoolYear = schoolYear
                    modelContext.insert(course)
                }
            }
        }
        
        try modelContext.save()
    }
    
    // MARK: - Data Export
    
    private func exportData(modelContext: ModelContext) async throws -> Data {
        // Fetch all data
        let descriptor = FetchDescriptor<Student>()
        let students = try modelContext.fetch(descriptor)
        
        let exportData = GradebookExport(
            version: "1.0.0",
            exportDate: Date(),
            students: students.map { student in
                StudentExport(
                    id: student.id,
                    name: student.name,
                    gradeLevel: student.grade,
                    schoolName: student.school,
                    schoolYears: student.schoolYears.map { year in
                        SchoolYearExport(
                            id: year.id,
                            year: year.year,
                            startDate: year.startDate,
                            endDate: year.endDate,
                            totalSchoolDays: year.totalSchoolDays,
                            subjects: year.subjects.map { subject in
                                SubjectExport(
                                    id: subject.id,
                                    name: subject.name,
                                    color: subject.color,
                                    credits: subject.credits,
                                    order: subject.order,
                                    dailyWeight: subject.dailyWeight,
                                    quizWeight: subject.quizWeight,
                                    testWeight: subject.testWeight,
                                    projectWeight: subject.projectWeight,
                                    otherWeight: subject.otherWeight,
                                    assignments: subject.assignments.map { assignment in
                                        AssignmentExport(
                                            id: assignment.id,
                                            name: assignment.title,
                                            category: assignment.type.rawValue,
                                            score: assignment.score,
                                            maxScore: assignment.maxScore,
                                            date: assignment.date,
                                            notes: assignment.notes
                                        )
                                    }
                                )
                            },
                            books: year.books.map { book in
                                BookExport(id: book.id, title: book.title, author: book.author, dateRead: book.dateRead, notes: book.notes)
                            },
                            activities: year.activities.map { activity in
                                ActivityExport(id: activity.id, date: activity.date, activityDescription: activity.activityDescription, role: activity.role)
                            },
                            fieldTrips: year.fieldTrips.map { trip in
                                FieldTripExport(id: trip.id, date: trip.date, tripDescription: trip.tripDescription, location: trip.location, notes: trip.notes)
                            },
                            courses: year.courses.map { course in
                                CourseExport(id: course.id, title: course.title, courseDescription: course.courseDescription, resources: course.resources)
                            }
                        )
                    }
                )
            }
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exportData)
    }
}

// MARK: - Export Data Models

struct GradebookExport: Codable {
    let version: String
    let exportDate: Date
    let students: [StudentExport]
}

struct StudentExport: Codable {
    let id: UUID
    let name: String
    let gradeLevel: String
    let schoolName: String
    let schoolYears: [SchoolYearExport]
}

struct SchoolYearExport: Codable {
    let id: UUID
    let year: String
    let startDate: Date
    let endDate: Date
    let totalSchoolDays: Int
    let subjects: [SubjectExport]
    let books: [BookExport]
    let activities: [ActivityExport]
    let fieldTrips: [FieldTripExport]
    let courses: [CourseExport]
}

struct SubjectExport: Codable {
    let id: UUID
    let name: String
    let color: String
    let credits: Double
    let order: Int
    let dailyWeight: Double
    let quizWeight: Double
    let testWeight: Double
    let projectWeight: Double
    let otherWeight: Double
    let assignments: [AssignmentExport]
}

struct AssignmentExport: Codable {
    let id: UUID
    let name: String
    let category: String
    let score: Double
    let maxScore: Double
    let date: Date
    let notes: String?
}

struct BookExport: Codable {
    let id: UUID
    let title: String
    let author: String
    let dateRead: Date
    let notes: String
}

struct ActivityExport: Codable {
    let id: UUID
    let date: Date
    let activityDescription: String
    let role: String
}

struct FieldTripExport: Codable {
    let id: UUID
    let date: Date
    let tripDescription: String
    let location: String
    let notes: String
}

struct CourseExport: Codable {
    let id: UUID
    let title: String
    let courseDescription: String
    let resources: String
}
