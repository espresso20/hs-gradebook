import SwiftUI
import SwiftData

struct SubjectsView: View {
    @Environment(\.modelContext) private var modelContext
    let schoolYear: SchoolYear
    @State private var showingNewSubject = false
    @State private var selectedSubject: Subject?
    @State private var subjectToDelete: Subject?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(schoolYear.subjects.sorted(by: { $0.order < $1.order })) { subject in
                    SubjectCard(subject: subject)
                        .onTapGesture {
                            selectedSubject = subject
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                subjectToDelete = subject
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Subject", systemImage: "trash")
                            }
                        }
                }
                
                Button(action: { showingNewSubject = true }) {
                    Label("Add New Subject", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle("Subjects")
        .toolbar {
            ToolbarItem {
                Button(action: { showingNewSubject = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewSubject) {
            NewSubjectView(schoolYear: schoolYear)
        }
        .sheet(item: $selectedSubject) { subject in
            SubjectDetailView(subject: subject)
        }
        .alert("Delete Subject?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let subject = subjectToDelete {
                    modelContext.delete(subject)
                    subjectToDelete = nil
                }
            }
        } message: {
            if let subject = subjectToDelete {
                Text("Are you sure you want to delete \(subject.name)? This will also delete all \(subject.assignments.count) assignments. This action cannot be undone.")
            }
        }
    }
}

struct SubjectCard: View {
    let subject: Subject
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Circle()
                    .fill(Color(hex: subject.color) ?? .blue)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(subject.credits, specifier: "%.1f") Credits")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(subject.weightedGrade, specifier: "%.1f")%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color(hex: subject.color) ?? .blue)
                    Text(subject.letterGrade)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            // Assignment type breakdown
            HStack(spacing: 20) {
                WeightLabel(title: "Daily", weight: subject.dailyWeight)
                WeightLabel(title: "Quizzes", weight: subject.quizWeight)
                WeightLabel(title: "Tests", weight: subject.testWeight)
                WeightLabel(title: "Projects", weight: subject.projectWeight)
                WeightLabel(title: "Other", weight: subject.otherWeight)
            }
            .font(.caption)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct WeightLabel: View {
    let title: String
    let weight: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .foregroundStyle(.secondary)
            Text("\(Int(weight * 100))%")
                .fontWeight(.semibold)
        }
    }
}

struct NewSubjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let schoolYear: SchoolYear
    
    @State private var name = ""
    @State private var credits: Double = 1.0
    @State private var color = Color.blue
    @State private var dailyWeight: Double = 20
    @State private var quizWeight: Double = 20
    @State private var testWeight: Double = 30
    @State private var projectWeight: Double = 20
    @State private var otherWeight: Double = 10
    
    private var totalWeight: Double {
        dailyWeight + quizWeight + testWeight + projectWeight + otherWeight
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Subject Information") {
                    TextField("Subject Name", text: $name)
                    
                    HStack {
                        Text("Credits")
                        Spacer()
                        TextField("Credits", value: $credits, format: .number)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                        Stepper("", value: $credits, in: 0...10, step: 0.5)
                            .labelsHidden()
                    }
                    
                    ColorPicker("Color", selection: $color)
                }
                
                Section(header: Text("Assignment Type Weights"), footer: Text("Total weight must equal 100%")) {
                    WeightSlider(title: "Daily", value: $dailyWeight)
                    WeightSlider(title: "Quizzes", value: $quizWeight)
                    WeightSlider(title: "Tests", value: $testWeight)
                    WeightSlider(title: "Projects", value: $projectWeight)
                    WeightSlider(title: "Other", value: $otherWeight)
                    
                    HStack {
                        Text("Total")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(Int(totalWeight))%")
                            .foregroundStyle(totalWeight == 100 ? .green : .red)
                            .fontWeight(.bold)
                    }
                    .padding(.vertical, 8)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Subject")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let subject = Subject(
                            name: name,
                            credits: credits,
                            color: color.toHex() ?? "#007AFF",
                            order: schoolYear.subjects.count
                        )
                        subject.dailyWeight = dailyWeight / 100
                        subject.quizWeight = quizWeight / 100
                        subject.testWeight = testWeight / 100
                        subject.projectWeight = projectWeight / 100
                        subject.otherWeight = otherWeight / 100
                        subject.schoolYear = schoolYear
                        modelContext.insert(subject)
                        dismiss()
                    }
                    .disabled(name.isEmpty || totalWeight != 100)
                }
            }
        }
        .frame(minWidth: 500, idealWidth: 550, maxWidth: 600, minHeight: 550, idealHeight: 600, maxHeight: 700)
        .padding()
    }
}

struct WeightSlider: View {
    let title: String
    @Binding var value: Double
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value))%")
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: 0...100, step: 5)
        }
    }
}

struct SubjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let subject: Subject
    @State private var showingNewAssignment = false
    @State private var showingDeleteConfirmation = false
    @State private var assignmentToDelete: Assignment?
    @State private var showingDeleteAssignmentConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Circle()
                            .fill(Color(hex: subject.color) ?? .blue)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading) {
                            Text(subject.name)
                                .font(.title)
                                .fontWeight(.bold)
                            Text("\(subject.credits, specifier: "%.1f") Credits")
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(subject.weightedGrade, specifier: "%.1f")%")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(Color(hex: subject.color) ?? .blue)
                            Text(subject.letterGrade)
                                .font(.headline)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // Assignments by type
                    ForEach(AssignmentType.allCases, id: \.self) { type in
                        let assignments = subject.assignments.filter { $0.type == type }
                        if !assignments.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(type.rawValue)
                                    .font(.headline)
                                
                                ForEach(assignments) { assignment in
                                    AssignmentRowView(assignment: assignment)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                assignmentToDelete = assignment
                                                showingDeleteAssignmentConfirmation = true
                                            } label: {
                                                Label("Delete Assignment", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    Button(action: { showingNewAssignment = true }) {
                        Label("Add Assignment", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle(subject.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .alert("Delete Subject?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    modelContext.delete(subject)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete \(subject.name)? This will also delete all \(subject.assignments.count) assignments. This action cannot be undone.")
            }
        }
        .frame(width: 700, height: 600)
        .sheet(isPresented: $showingNewAssignment) {
            NewAssignmentView(subject: subject)
        }
        .alert("Delete Assignment?", isPresented: $showingDeleteAssignmentConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let assignment = assignmentToDelete {
                    modelContext.delete(assignment)
                    assignmentToDelete = nil
                }
            }
        } message: {
            if let assignment = assignmentToDelete {
                Text("Are you sure you want to delete \"\(assignment.title)\"? This action cannot be undone.")
            }
        }
    }
}

struct AssignmentRowView: View {
    let assignment: Assignment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.title)
                    .font(.headline)
                Text(assignment.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(assignment.percentage, specifier: "%.0f")%")
                .font(.headline)
                .foregroundStyle(gradeColor(for: assignment.percentage))
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
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

// MARK: - Color Extension
extension Color {
    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components else { return nil }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}

#Preview {
    SubjectsView(schoolYear: SchoolYear(year: "2024-2025"))
        .modelContainer(for: [Subject.self], inMemory: true)
}
