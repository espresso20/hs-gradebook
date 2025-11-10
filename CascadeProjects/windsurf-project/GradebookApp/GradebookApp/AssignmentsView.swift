import SwiftUI
import SwiftData

struct AssignmentsView: View {
    let schoolYear: SchoolYear
    @State private var showingNewAssignment = false
    @State private var selectedSubject: Subject?
    @State private var searchText = ""
    @State private var filterType: AssignmentType?
    
    var allAssignments: [Assignment] {
        schoolYear.subjects.flatMap { $0.assignments }
            .filter { assignment in
                (searchText.isEmpty || assignment.title.localizedCaseInsensitiveContains(searchText)) &&
                (filterType == nil || assignment.type == filterType)
            }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Bar
            HStack {
                ForEach([nil] + AssignmentType.allCases.map { Optional($0) }, id: \.self) { type in
                    Button(action: { filterType = type }) {
                        Text(type?.rawValue ?? "All")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(filterType == type ? .blue : .secondary.opacity(0.2),
                                      in: Capsule())
                            .foregroundStyle(filterType == type ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Assignment List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(allAssignments) { assignment in
                        AssignmentDetailCard(assignment: assignment)
                    }
                }
                .padding()
            }
            .searchable(text: $searchText, prompt: "Search assignments...")
        }
        .navigationTitle("Assignments")
        .toolbar {
            ToolbarItemGroup {
                Menu {
                    ForEach(schoolYear.subjects) { subject in
                        Button(action: {
                            selectedSubject = subject
                            showingNewAssignment = true
                        }) {
                            Label(subject.name, systemImage: "book")
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewAssignment) {
            if let subject = selectedSubject {
                NewAssignmentView(subject: subject)
            }
        }
    }
}

struct AssignmentDetailCard: View {
    let assignment: Assignment
    
    var body: some View {
        HStack(spacing: 16) {
            // Subject color indicator
            if let subject = assignment.subject {
                Rectangle()
                    .fill(Color(hex: subject.color) ?? .blue)
                    .frame(width: 4)
                    .cornerRadius(2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(assignment.title)
                        .font(.headline)
                    Spacer()
                    Text(assignment.type.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.2), in: Capsule())
                }
                
                HStack {
                    if let subject = assignment.subject {
                        Text(subject.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(assignment.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if !assignment.notes.isEmpty {
                    Text(assignment.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            VStack(spacing: 4) {
                Text("\(assignment.percentage, specifier: "%.0f")%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(gradeColor(for: assignment.percentage))
                
                Text("\(assignment.score, specifier: "%.0f")/\(assignment.maxScore, specifier: "%.0f")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    func gradeColor(for percentage: Double) -> Color {
        switch percentage {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .orange
        default: return .red
        }
    }
}

struct NewAssignmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let subject: Subject
    
    @State private var title = ""
    @State private var type: AssignmentType
    @State private var date = Date()
    @State private var score: Double = 0
    @State private var maxScore: Double = 100
    @State private var notes = ""
    
    init(subject: Subject) {
        self.subject = subject
        // Set initial type to first enabled type
        let enabledTypes = Self.enabledTypes(for: subject)
        _type = State(initialValue: enabledTypes.first ?? .daily)
    }
    
    private static func enabledTypes(for subject: Subject) -> [AssignmentType] {
        AssignmentType.allCases.filter { type in
            switch type {
            case .daily: return subject.dailyWeight > 0
            case .quiz: return subject.quizWeight > 0
            case .test: return subject.testWeight > 0
            case .project: return subject.projectWeight > 0
            case .other: return subject.otherWeight > 0
            }
        }
    }
    
    private var enabledTypes: [AssignmentType] {
        Self.enabledTypes(for: subject)
    }
    
    private var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return (score / maxScore) * 100
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Assignment Details") {
                    LabeledContent("Title") {
                        TextField("Assignment name", text: $title)
                            .multilineTextAlignment(.trailing)
                            .characterLimit(CharacterLimits.title, text: $title)
                    }
                    
                    LabeledContent("Type") {
                        Picker("Type", selection: $type) {
                            ForEach(enabledTypes, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .labelsHidden()
                    }
                    
                    LabeledContent("Date") {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
                
                Section("Grading") {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            // Score Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Score")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                HStack {
                                    TextField("0", value: $score, format: .number)
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.center)
                                        .font(.title3)
                                        .frame(height: 44)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.primary.opacity(0.05))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                            
                            Text("/")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                                .padding(.top, 24)
                            
                            // Max Score Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Max Score")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                HStack {
                                    TextField("100", value: $maxScore, format: .number)
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.center)
                                        .font(.title3)
                                        .frame(height: 44)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.primary.opacity(0.05))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Percentage Display
                        HStack {
                            Text("Percentage")
                                .font(.headline)
                            Spacer()
                            Text("\(percentage, specifier: "%.1f")%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(gradeColor(for: percentage))
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80, maxHeight: 150)
                        .scrollContentBackground(.hidden)
                        .characterLimit(CharacterLimits.notes, text: $notes)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Assignment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let assignment = Assignment(
                            title: title,
                            type: type,
                            date: date,
                            score: score,
                            maxScore: maxScore,
                            notes: notes
                        )
                        assignment.subject = subject
                        modelContext.insert(assignment)
                        dismiss()
                    }
                    .disabled(title.isEmpty || maxScore <= 0)
                }
            }
        }
        .frame(minWidth: 500, idealWidth: 550, maxWidth: 600, minHeight: 500, idealHeight: 550, maxHeight: 700)
        .padding()
    }
    
    private func gradeColor(for percentage: Double) -> Color {
        switch percentage {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .orange
        default: return .red
        }
    }
}

#Preview {
    AssignmentsView(schoolYear: SchoolYear(year: "2024-2025"))
        .modelContainer(for: [Assignment.self], inMemory: true)
}
