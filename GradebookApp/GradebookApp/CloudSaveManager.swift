import Foundation
import SwiftData
import Security

// MARK: - Cloud Save Manager
class CloudSaveManager: ObservableObject {
    @Published var lastSaveDate: Date?
    @Published var isSaving = false
    @Published var saveError: String?
    @Published var credentialsConfigured = false
    
    private let keychainService = "com.gradebookplus.aws"
    
    init() {
        checkCredentials()
    }
    
    // MARK: - Credential Management
    
    func saveCredentials(accessKey: String, secretKey: String, bucket: String, region: String) {
        // Save to Keychain
        let credentials = AWSCredentials(
            accessKey: accessKey,
            secretKey: secretKey,
            bucket: bucket,
            region: region
        )
        
        if let data = try? JSONEncoder().encode(credentials) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: "aws-credentials",
                kSecValueData as String: data
            ]
            
            // Delete existing
            SecItemDelete(query as CFDictionary)
            
            // Add new
            let status = SecItemAdd(query as CFDictionary, nil)
            if status == errSecSuccess {
                credentialsConfigured = true
            }
        }
    }
    
    func clearCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "aws-credentials"
        ]
        SecItemDelete(query as CFDictionary)
        credentialsConfigured = false
    }
    
    private func checkCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "aws-credentials",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        credentialsConfigured = (status == errSecSuccess)
    }
    
    private func getCredentials() -> AWSCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "aws-credentials",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let credentials = try? JSONDecoder().decode(AWSCredentials.self, from: data) else {
            return nil
        }
        
        return credentials
    }
    
    // MARK: - Save to Cloud
    
    func saveToCloud(modelContext: ModelContext) async {
        await MainActor.run {
            isSaving = true
            saveError = nil
        }
        
        do {
            guard let credentials = getCredentials() else {
                throw CloudSaveError.noCredentials
            }
            
            // Export all data
            let exportData = try await exportAllData(modelContext: modelContext)
            
            // Upload to S3
            try await uploadToS3(data: exportData, credentials: credentials)
            
            await MainActor.run {
                lastSaveDate = Date()
                isSaving = false
                
                // Save last save date to UserDefaults
                UserDefaults.standard.set(lastSaveDate, forKey: "lastCloudSave")
            }
        } catch {
            await MainActor.run {
                saveError = error.localizedDescription
                isSaving = false
            }
        }
    }
    
    // MARK: - Data Export
    
    private func exportAllData(modelContext: ModelContext) async throws -> Data {
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
    
    // MARK: - S3 Upload
    
    private func uploadToS3(data: Data, credentials: AWSCredentials) async throws {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = "gradebook-\(timestamp).json"
        let urlString = "https://\(credentials.bucket).s3.\(credentials.region).amazonaws.com/\(filename)"
        
        guard let url = URL(string: urlString) else {
            throw CloudSaveError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        
        // Add AWS signature (simplified - using AWS Signature V4)
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let amzDate = dateFormatter.string(from: date)
        
        request.setValue(amzDate, forHTTPHeaderField: "x-amz-date")
        request.setValue("AWS4-HMAC-SHA256 Credential=\(credentials.accessKey)/\(String(amzDate.prefix(8)))/\(credentials.region)/s3/aws4_request, SignedHeaders=host;x-amz-date, Signature=", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CloudSaveError.uploadFailed
        }
    }
}

// MARK: - Models

struct AWSCredentials: Codable {
    let accessKey: String
    let secretKey: String
    let bucket: String
    let region: String
}

enum CloudSaveError: LocalizedError {
    case noCredentials
    case invalidURL
    case uploadFailed
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .noCredentials: return "AWS credentials not configured"
        case .invalidURL: return "Invalid S3 URL"
        case .uploadFailed: return "Failed to upload to S3"
        case .exportFailed: return "Failed to export data"
        }
    }
}

// MARK: - Export Models

struct GradebookExport: Codable {
    let version: String
    let exportDate: Date
    let students: [StudentExport]
}

struct StudentExport: Codable {
    let id: UUID
    let name: String
    let gradeLevel: String?
    let schoolName: String?
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
