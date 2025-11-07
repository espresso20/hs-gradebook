import Foundation
import SwiftData

// MARK: - Student Model
@Model
final class Student {
    var id: UUID
    var name: String
    var grade: String
    var school: String
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade) var schoolYears: [SchoolYear]
    
    init(name: String, grade: String = "", school: String = "") {
        self.id = UUID()
        self.name = name
        self.grade = grade
        self.school = school
        self.createdAt = Date()
        self.schoolYears = []
    }
}

// MARK: - School Year Model
@Model
final class SchoolYear {
    var id: UUID
    var year: String
    var startDate: Date
    var endDate: Date
    var totalSchoolDays: Int
    var student: Student?
    
    @Relationship(deleteRule: .cascade) var subjects: [Subject]
    @Relationship(deleteRule: .cascade) var books: [Book]
    @Relationship(deleteRule: .cascade) var activities: [Activity]
    @Relationship(deleteRule: .cascade) var fieldTrips: [FieldTrip]
    @Relationship(deleteRule: .cascade) var courses: [Course]
    
    init(year: String, startDate: Date = Date(), endDate: Date = Date(), totalSchoolDays: Int = 180) {
        self.id = UUID()
        self.year = year
        self.startDate = startDate
        self.endDate = endDate
        self.totalSchoolDays = totalSchoolDays
        self.subjects = []
        self.books = []
        self.activities = []
        self.fieldTrips = []
        self.courses = []
    }
}

// MARK: - Subject Model
@Model
final class Subject {
    var id: UUID
    var name: String
    var credits: Double
    var color: String // Store as hex color string
    var order: Int
    var schoolYear: SchoolYear?
    
    // Weight percentages for different assignment types
    var dailyWeight: Double
    var quizWeight: Double
    var testWeight: Double
    var projectWeight: Double
    var otherWeight: Double
    
    @Relationship(deleteRule: .cascade) var assignments: [Assignment]
    
    init(name: String, credits: Double = 1.0, color: String = "#007AFF", order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.credits = credits
        self.color = color
        self.order = order
        self.dailyWeight = 0.2
        self.quizWeight = 0.2
        self.testWeight = 0.3
        self.projectWeight = 0.2
        self.otherWeight = 0.1
        self.assignments = []
    }
    
    var weightedGrade: Double {
        // If no assignments exist, return 0
        guard !assignments.isEmpty else { return 0 }
        
        // Get assignments by type and calculate percentage averages
        let dailyGrades = assignments.filter { $0.type == .daily }.map { $0.percentage }
        let quizGrades = assignments.filter { $0.type == .quiz }.map { $0.percentage }
        let testGrades = assignments.filter { $0.type == .test }.map { $0.percentage }
        let projectGrades = assignments.filter { $0.type == .project }.map { $0.percentage }
        let otherGrades = assignments.filter { $0.type == .other }.map { $0.percentage }
        
        // Calculate averages for each type
        let dailyAvg = dailyGrades.isEmpty ? nil : dailyGrades.reduce(0, +) / Double(dailyGrades.count)
        let quizAvg = quizGrades.isEmpty ? nil : quizGrades.reduce(0, +) / Double(quizGrades.count)
        let testAvg = testGrades.isEmpty ? nil : testGrades.reduce(0, +) / Double(testGrades.count)
        let projectAvg = projectGrades.isEmpty ? nil : projectGrades.reduce(0, +) / Double(projectGrades.count)
        let otherAvg = otherGrades.isEmpty ? nil : otherGrades.reduce(0, +) / Double(otherGrades.count)
        
        // Calculate total weight of categories that have assignments
        var totalActiveWeight: Double = 0
        var weightedSum: Double = 0
        
        if let avg = dailyAvg {
            weightedSum += avg * dailyWeight
            totalActiveWeight += dailyWeight
        }
        if let avg = quizAvg {
            weightedSum += avg * quizWeight
            totalActiveWeight += quizWeight
        }
        if let avg = testAvg {
            weightedSum += avg * testWeight
            totalActiveWeight += testWeight
        }
        if let avg = projectAvg {
            weightedSum += avg * projectWeight
            totalActiveWeight += projectWeight
        }
        if let avg = otherAvg {
            weightedSum += avg * otherWeight
            totalActiveWeight += otherWeight
        }
        
        // Normalize by dividing by the total weight of categories with assignments
        guard totalActiveWeight > 0 else { return 0 }
        return weightedSum / totalActiveWeight
    }
    
    var letterGrade: String {
        let grade = weightedGrade
        switch grade {
        case 98...100: return "A+"
        case 93..<98: return "A"
        case 90..<93: return "A-"
        case 88..<90: return "B+"
        case 83..<88: return "B"
        case 80..<83: return "B-"
        case 78..<80: return "C+"
        case 73..<78: return "C"
        case 70..<73: return "C-"
        case 68..<70: return "D+"
        case 63..<68: return "D"
        case 60..<63: return "D-"
        default: return "F"
        }
    }
}

// MARK: - Assignment Model
@Model
final class Assignment {
    var id: UUID
    var title: String
    var type: AssignmentType
    var date: Date
    var score: Double // 0-100
    var maxScore: Double
    var notes: String
    var subject: Subject?
    
    init(title: String, type: AssignmentType, date: Date = Date(), score: Double = 0, maxScore: Double = 100, notes: String = "") {
        self.id = UUID()
        self.title = title
        self.type = type
        self.date = date
        self.score = score
        self.maxScore = maxScore
        self.notes = notes
    }
    
    var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return (score / maxScore) * 100
    }
}

enum AssignmentType: String, Codable, CaseIterable {
    case daily = "Daily"
    case quiz = "Quiz"
    case test = "Test"
    case project = "Project"
    case other = "Other"
}

// MARK: - Book Model
@Model
final class Book {
    var id: UUID
    var title: String
    var author: String
    var dateRead: Date
    var notes: String
    var schoolYear: SchoolYear?
    
    init(title: String, author: String, dateRead: Date = Date(), notes: String = "") {
        self.id = UUID()
        self.title = title
        self.author = author
        self.dateRead = dateRead
        self.notes = notes
    }
}

// MARK: - Activity Model
@Model
final class Activity {
    var id: UUID
    var date: Date
    var activityDescription: String
    var role: String
    var schoolYear: SchoolYear?
    
    init(date: Date = Date(), activityDescription: String, role: String = "") {
        self.id = UUID()
        self.date = date
        self.activityDescription = activityDescription
        self.role = role
    }
}

// MARK: - Field Trip Model
@Model
final class FieldTrip {
    var id: UUID
    var date: Date
    var tripDescription: String
    var location: String
    var notes: String
    var schoolYear: SchoolYear?
    
    init(date: Date = Date(), tripDescription: String, location: String = "", notes: String = "") {
        self.id = UUID()
        self.date = date
        self.tripDescription = tripDescription
        self.location = location
        self.notes = notes
    }
}

// MARK: - Course Model
@Model
final class Course {
    var id: UUID
    var title: String
    var courseDescription: String
    var resources: String
    var schoolYear: SchoolYear?
    
    init(title: String, courseDescription: String = "", resources: String = "") {
        self.id = UUID()
        self.title = title
        self.courseDescription = courseDescription
        self.resources = resources
    }
}
