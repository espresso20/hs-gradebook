import Foundation
import SwiftUI

// MARK: - Grading Scale Types

enum GradingScaleType: String, CaseIterable, Codable {
    case granular = "Granular (A+, A, A-, etc.)"
    case simple = "Simple (A, B, C, etc.)"
    
    var displayName: String { rawValue }
    
    var description: String {
        switch self {
        case .granular:
            return "13 grade levels with plus/minus variations"
        case .simple:
            return "5 grade levels (A, B, C, D, F)"
        }
    }
}

// MARK: - Grade Scale Item

struct GradeScaleItem: Identifiable {
    let id = UUID()
    let letter: String
    let minScore: Double
    let maxScore: Double
    
    var range: String {
        if maxScore == 100 {
            return "\(Int(minScore))-\(Int(maxScore))"
        } else {
            return "\(Int(minScore))-\(Int(maxScore - 1))"
        }
    }
}

// MARK: - Grading Scale Definitions

struct GradingScaleDefinition {
    static let granularScale: [GradeScaleItem] = [
        GradeScaleItem(letter: "A+", minScore: 98, maxScore: 100),
        GradeScaleItem(letter: "A", minScore: 93, maxScore: 98),
        GradeScaleItem(letter: "A-", minScore: 90, maxScore: 93),
        GradeScaleItem(letter: "B+", minScore: 88, maxScore: 90),
        GradeScaleItem(letter: "B", minScore: 83, maxScore: 88),
        GradeScaleItem(letter: "B-", minScore: 80, maxScore: 83),
        GradeScaleItem(letter: "C+", minScore: 78, maxScore: 80),
        GradeScaleItem(letter: "C", minScore: 73, maxScore: 78),
        GradeScaleItem(letter: "C-", minScore: 70, maxScore: 73),
        GradeScaleItem(letter: "D+", minScore: 68, maxScore: 70),
        GradeScaleItem(letter: "D", minScore: 63, maxScore: 68),
        GradeScaleItem(letter: "D-", minScore: 60, maxScore: 63),
        GradeScaleItem(letter: "F", minScore: 0, maxScore: 60)
    ]
    
    static let simpleScale: [GradeScaleItem] = [
        GradeScaleItem(letter: "A", minScore: 90, maxScore: 100),
        GradeScaleItem(letter: "B", minScore: 80, maxScore: 90),
        GradeScaleItem(letter: "C", minScore: 70, maxScore: 80),
        GradeScaleItem(letter: "D", minScore: 60, maxScore: 70),
        GradeScaleItem(letter: "F", minScore: 0, maxScore: 60)
    ]
    
    static func scale(for type: GradingScaleType) -> [GradeScaleItem] {
        switch type {
        case .granular:
            return granularScale
        case .simple:
            return simpleScale
        }
    }
    
    static func letterGrade(for percentage: Double, scaleType: GradingScaleType) -> String {
        let scale = self.scale(for: scaleType)
        
        for item in scale {
            if percentage >= item.minScore && percentage <= item.maxScore {
                return item.letter
            }
        }
        
        return "F"
    }
}

// MARK: - App Storage Helper

extension AppStorage {
    init(wrappedValue: Value, _ key: String) where Value == GradingScaleType {
        self.init(wrappedValue: wrappedValue, key, store: .standard)
    }
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    var gradingScaleType: GradingScaleType {
        get {
            guard let rawValue = string(forKey: "gradingScaleType"),
                  let type = GradingScaleType(rawValue: rawValue) else {
                return .granular // Default
            }
            return type
        }
        set {
            set(newValue.rawValue, forKey: "gradingScaleType")
        }
    }
}
