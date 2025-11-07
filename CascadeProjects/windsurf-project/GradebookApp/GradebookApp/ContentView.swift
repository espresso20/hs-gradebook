import SwiftUI
import SwiftData
import Charts

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var students: [Student]
    @State private var selectedStudent: Student?
    @State private var selectedSchoolYear: SchoolYear?
    @State private var selectedView: NavigationItem = .dashboard
    @State private var showingNewStudentSheet = false
    @State private var showingNewSchoolYearSheet = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView(
                students: students,
                selectedStudent: $selectedStudent,
                selectedSchoolYear: $selectedSchoolYear,
                selectedView: $selectedView,
                showingNewStudentSheet: $showingNewStudentSheet,
                showingNewSchoolYearSheet: $showingNewSchoolYearSheet
            )
        } detail: {
            // Main content area
            if let student = selectedStudent, let schoolYear = selectedSchoolYear {
                MainContentView(
                    student: student,
                    schoolYear: schoolYear,
                    selectedView: selectedView
                )
            } else {
                WelcomeView(showingNewStudentSheet: $showingNewStudentSheet)
            }
        }
        .sheet(isPresented: $showingNewStudentSheet) {
            NewStudentView()
        }
        .sheet(isPresented: $showingNewSchoolYearSheet) {
            if let student = selectedStudent {
                NewSchoolYearView(student: student)
            }
        }
        .onAppear {
            if selectedStudent == nil && !students.isEmpty {
                selectedStudent = students.first
                selectedSchoolYear = students.first?.schoolYears.first
            }
        }
    }
}

// MARK: - Navigation Item
enum NavigationItem: String, CaseIterable {
    case dashboard = "Dashboard"
    case subjects = "Subjects"
    case assignments = "Assignments"
    case books = "Books"
    case activities = "Activities"
    case fieldTrips = "Field Trips"
    case courses = "Courses"
    case reports = "Reports"
    case help = "Help"
    
    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .subjects: return "book.fill"
        case .assignments: return "doc.text.fill"
        case .books: return "books.vertical.fill"
        case .activities: return "figure.run"
        case .fieldTrips: return "bus.fill"
        case .courses: return "graduationcap.fill"
        case .reports: return "chart.line.uptrend.xyaxis"
        case .help: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    let students: [Student]
    @Binding var selectedStudent: Student?
    @Binding var selectedSchoolYear: SchoolYear?
    @Binding var selectedView: NavigationItem
    @Binding var showingNewStudentSheet: Bool
    @Binding var showingNewSchoolYearSheet: Bool
    @State private var expandedStudentId: UUID?
    @State private var studentToDelete: Student?
    @State private var showingDeleteStudentConfirmation = false
    @State private var schoolYearToDelete: SchoolYear?
    @State private var showingDeleteSchoolYearConfirmation = false
    
    var body: some View {
        List(selection: $selectedView) {
            Section("Students") {
                ForEach(students) { student in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedStudentId == student.id },
                            set: { isExpanded in
                                expandedStudentId = isExpanded ? student.id : nil
                                if isExpanded {
                                    selectedStudent = student
                                    if let firstYear = student.schoolYears.first {
                                        selectedSchoolYear = firstYear
                                    }
                                }
                            }
                        )
                    ) {
                        ForEach(student.schoolYears) { year in
                            Button(action: {
                                selectedStudent = student
                                selectedSchoolYear = year
                            }) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(.secondary)
                                    Text(year.year)
                                    if selectedSchoolYear?.id == year.id {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    schoolYearToDelete = year
                                    showingDeleteSchoolYearConfirmation = true
                                } label: {
                                    Label("Delete School Year", systemImage: "trash")
                                }
                            }
                        }
                        
                        Button(action: {
                            selectedStudent = student
                            showingNewSchoolYearSheet = true
                        }) {
                            Label("Add School Year", systemImage: "plus.circle")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    } label: {
                        Label(student.name, systemImage: "person.fill")
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            studentToDelete = student
                            showingDeleteStudentConfirmation = true
                        } label: {
                            Label("Delete Student", systemImage: "trash")
                        }
                    }
                }
            }
            
            Section {
                Button(action: { showingNewStudentSheet = true }) {
                    Label("New Student", systemImage: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            
            if selectedStudent != nil && selectedSchoolYear != nil {
                Section("Navigation") {
                    ForEach(NavigationItem.allCases.filter { $0 != .help }, id: \.self) { item in
                        NavigationLink(value: item) {
                            Label(item.rawValue, systemImage: item.icon)
                        }
                    }
                }
            }
            
            Section {
                NavigationLink(value: NavigationItem.help) {
                    Label("Help & Documentation", systemImage: "questionmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Gradebook Plus")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewStudentSheet = true }) {
                    Image(systemName: "plus")
                }
                .help("Add new student")
            }
        }
        .onAppear {
            // Auto-expand first student if nothing is selected
            if expandedStudentId == nil && !students.isEmpty {
                expandedStudentId = students.first?.id
            }
        }
        .alert("Delete Student?", isPresented: $showingDeleteStudentConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let student = studentToDelete {
                    if selectedStudent?.id == student.id {
                        selectedStudent = nil
                        selectedSchoolYear = nil
                    }
                    modelContext.delete(student)
                    studentToDelete = nil
                }
            }
        } message: {
            if let student = studentToDelete {
                let yearCount = student.schoolYears.count
                let subjectCount = student.schoolYears.flatMap { $0.subjects }.count
                Text("Are you sure you want to delete \(student.name)? This will permanently delete \(yearCount) school year(s) and \(subjectCount) subject(s). This action cannot be undone.")
            }
        }
        .alert("Delete School Year?", isPresented: $showingDeleteSchoolYearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let schoolYear = schoolYearToDelete {
                    if selectedSchoolYear?.id == schoolYear.id {
                        selectedSchoolYear = nil
                    }
                    modelContext.delete(schoolYear)
                    schoolYearToDelete = nil
                }
            }
        } message: {
            if let schoolYear = schoolYearToDelete {
                let subjectCount = schoolYear.subjects.count
                let assignmentCount = schoolYear.subjects.flatMap { $0.assignments }.count
                Text("Are you sure you want to delete the \(schoolYear.year) school year? This will permanently delete \(subjectCount) subject(s) and \(assignmentCount) assignment(s). This action cannot be undone.")
            }
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    @Binding var showingNewStudentSheet: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "graduationcap.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 12) {
                Text("Welcome to Gradebook Plus")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("A modern homeschool gradebook for tracking student progress")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingNewStudentSheet = true }) {
                Label("Create Your First Student", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(50)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Main Content View
struct MainContentView: View {
    let student: Student
    let schoolYear: SchoolYear
    let selectedView: NavigationItem
    
    var body: some View {
        Group {
            switch selectedView {
            case .dashboard:
                DashboardView(student: student, schoolYear: schoolYear)
            case .subjects:
                SubjectsView(schoolYear: schoolYear)
            case .assignments:
                AssignmentsView(schoolYear: schoolYear)
            case .books:
                BooksView(schoolYear: schoolYear)
            case .activities:
                ActivitiesView(schoolYear: schoolYear)
            case .fieldTrips:
                FieldTripsView(schoolYear: schoolYear)
            case .courses:
                CoursesView(schoolYear: schoolYear)
            case .reports:
                ReportsView(student: student, schoolYear: schoolYear)
            case .help:
                HelpView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    let student: Student
    let schoolYear: SchoolYear
    
    var overallGPA: Double {
        let grades = schoolYear.subjects.map { $0.weightedGrade }
        guard !grades.isEmpty else { return 0 }
        return grades.reduce(0, +) / Double(grades.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(student.name)
                        .font(.system(size: 36, weight: .bold))
                    HStack {
                        Label(schoolYear.year, systemImage: "calendar")
                        Spacer()
                        Label("GPA: \(overallGPA, specifier: "%.1f")", systemImage: "chart.bar.fill")
                            .font(.headline)
                    }
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(
                        title: "Subjects",
                        value: "\(schoolYear.subjects.count)",
                        icon: "book.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Assignments",
                        value: "\(schoolYear.subjects.flatMap { $0.assignments }.count)",
                        icon: "doc.text.fill",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Books Read",
                        value: "\(schoolYear.books.count)",
                        icon: "books.vertical.fill",
                        color: .purple
                    )
                    
                    StatCard(
                        title: "Activities",
                        value: "\(schoolYear.activities.count)",
                        icon: "figure.run",
                        color: .orange
                    )
                }
                
                // Subjects Performance Chart
                if !schoolYear.subjects.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Subject Performance")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Chart(schoolYear.subjects.sorted(by: { $0.order < $1.order })) { subject in
                            BarMark(
                                x: .value("Subject", subject.name),
                                y: .value("Grade", subject.weightedGrade)
                            )
                            .foregroundStyle(Color(hex: subject.color) ?? .blue)
                            .annotation(position: .top) {
                                Text(subject.letterGrade)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                        .chartYScale(domain: 0...100)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 250)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Subjects")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    ForEach(schoolYear.subjects.prefix(5)) { subject in
                        SubjectRowView(subject: subject)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color.gradient)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Subject Row View
struct SubjectRowView: View {
    let subject: Subject
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: subject.color) ?? .blue)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subject.name)
                    .font(.headline)
                Text("\(subject.assignments.count) assignments")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(subject.weightedGrade, specifier: "%.1f")%")
                    .font(.headline)
                    .foregroundStyle(Color(hex: subject.color) ?? .blue)
                Text(subject.letterGrade)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - New Student View
struct NewStudentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var grade = ""
    @State private var school = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Student Information") {
                    TextField("Full Name", text: $name)
                    TextField("Grade Level", text: $grade)
                    TextField("School Name", text: $school)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Student")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let student = Student(name: name, grade: grade, school: school)
                        modelContext.insert(student)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}

// MARK: - New School Year View
struct NewSchoolYearView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let student: Student
    @State private var year = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 9, to: Date()) ?? Date()
    @State private var totalDays = 180
    
    var body: some View {
        NavigationStack {
            Form {
                Section("School Year Information") {
                    TextField("Year (e.g., 2024-2025)", text: $year)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    Stepper("Total School Days: \(totalDays)", value: $totalDays, in: 1...365)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New School Year")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let schoolYear = SchoolYear(
                            year: year,
                            startDate: startDate,
                            endDate: endDate,
                            totalSchoolDays: totalDays
                        )
                        schoolYear.student = student
                        modelContext.insert(schoolYear)
                        dismiss()
                    }
                    .disabled(year.isEmpty)
                }
            }
        }
        .frame(width: 450, height: 350)
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}

// MARK: - Help View
struct HelpView: View {
    @State private var selectedSection: HelpSection = .gettingStarted
    
    var body: some View {
        HSplitView {
            // Help Navigation
            List(HelpSection.allCases, id: \.self, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
            
            // Help Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HelpContentView(section: selectedSection)
                }
                .padding(30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Help & Documentation")
    }
}

enum HelpSection: String, CaseIterable {
    case gettingStarted = "Getting Started"
    case students = "Managing Students"
    case schoolYears = "School Years"
    case subjects = "Subjects & Grading"
    case assignments = "Assignments"
    case books = "Reading List"
    case activities = "Activities"
    case fieldTrips = "Field Trips"
    case courses = "Course Descriptions"
    case reports = "Reports"
    case tips = "Tips & Tricks"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .gettingStarted: return "flag.fill"
        case .students: return "person.fill"
        case .schoolYears: return "calendar"
        case .subjects: return "book.fill"
        case .assignments: return "doc.text.fill"
        case .books: return "books.vertical.fill"
        case .activities: return "figure.run"
        case .fieldTrips: return "bus.fill"
        case .courses: return "graduationcap.fill"
        case .reports: return "chart.line.uptrend.xyaxis"
        case .tips: return "lightbulb.fill"
        }
    }
}

struct HelpContentView: View {
    let section: HelpSection
    
    var body: some View {
        switch section {
        case .gettingStarted:
            GettingStartedContent()
        case .students:
            StudentsHelpContent()
        case .schoolYears:
            SchoolYearsHelpContent()
        case .subjects:
            SubjectsHelpContent()
        case .assignments:
            AssignmentsHelpContent()
        case .books:
            BooksHelpContent()
        case .activities:
            ActivitiesHelpContent()
        case .fieldTrips:
            FieldTripsHelpContent()
        case .courses:
            CoursesHelpContent()
        case .reports:
            ReportsHelpContent()
        case .tips:
            TipsHelpContent()
        }
    }
}

// MARK: - Help Content Sections

struct GettingStartedContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpHeader(title: "Getting Started with Gradebook Plus")
            
            HelpParagraph(text: "Gradebook Plus is a comprehensive homeschool grade tracking application designed to help you manage students, subjects, assignments, and generate detailed reports.")
            
            HelpSubheader(title: "Quick Start Guide")
            HelpStep(number: 1, title: "Create a Student", description: "Click the 'New Student' button in the sidebar or toolbar to add your first student.")
            HelpStep(number: 2, title: "Add a School Year", description: "Expand the student and click 'Add School Year' to create a school year with start/end dates.")
            HelpStep(number: 3, title: "Create Subjects", description: "Navigate to 'Subjects' and add subjects with customizable grade weights.")
            HelpStep(number: 4, title: "Add Assignments", description: "Within each subject or from the Assignments view, add graded work.")
            HelpStep(number: 5, title: "Track Progress", description: "View the Dashboard for an overview and generate Reports for detailed analysis.")
            
            HelpTip(text: "Pro Tip: Start by setting up all your subjects first, then add assignments as you go throughout the school year.")
        }
    }
}

struct StudentsHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpHeader(title: "Managing Students")
            
            HelpSubheader(title: "Adding a Student")
            HelpParagraph(text: "Click the 'New Student' button or the + icon in the toolbar. Enter the student's name, grade level, and school name. Only the name is required.")
            
            HelpSubheader(title: "Selecting a Student")
            HelpParagraph(text: "Click on a student's name in the sidebar to expand and view their school years. The student will be automatically selected.")
            
            HelpSubheader(title: "Deleting a Student")
            HelpParagraph(text: "Right-click (Control+click) on a student's name and select 'Delete Student'. This will remove all school years, subjects, and assignments for that student.")
            
            HelpWarning(text: "Warning: Deleting a student cannot be undone. All associated data will be permanently removed.")
        }
    }
}

struct SchoolYearsHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpHeader(title: "School Years")
            
            HelpSubheader(title: "Creating a School Year")
            HelpParagraph(text: "Expand a student in the sidebar and click 'Add School Year'. Enter the year (e.g., '2024-2025'), start date, end date, and total school days (default: 180).")
            
            HelpSubheader(title: "Managing School Years")
            HelpParagraph(text: "You can have multiple school years per student to track progress over time. Each school year contains its own subjects, assignments, books, activities, field trips, and courses.")
            
            HelpSubheader(title: "Deleting a School Year")
            HelpParagraph(text: "Right-click on a school year and select 'Delete School Year'. This will remove all associated data for that year.")
        }
    }
}

struct SubjectsHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpHeader(title: "Subjects & Grading")
            
            HelpSubheader(title: "Creating a Subject")
            HelpParagraph(text: "Navigate to 'Subjects' and click the + button. Enter the subject name, credits, and choose a color for easy identification.")
            
            HelpSubheader(title: "Grade Weights")
            HelpParagraph(text: "Customize how different assignment types contribute to the final grade:")
            HelpBullet(text: "Daily: Homework and daily work")
            HelpBullet(text: "Quizzes: Short assessments")
            HelpBullet(text: "Tests: Major exams")
            HelpBullet(text: "Projects: Long-term assignments")
            HelpBullet(text: "Other: Additional work")
            
            HelpParagraph(text: "The total must equal 100%. Default weights are: Daily 20%, Quizzes 20%, Tests 30%, Projects 20%, Other 10%.")
            
            HelpSubheader(title: "Grade Calculation")
            HelpParagraph(text: "Grades are automatically calculated based on the weighted average of assignments in each category. Only categories with assignments are counted, so you can have assignments in just one category and still get accurate grades.")
            
            HelpSubheader(title: "Letter Grades")
            HelpParagraph(text: "Letter grades are assigned as follows:")
            HelpBullet(text: "A+: 98-100%  |  A: 93-97%  |  A-: 90-92%")
            HelpBullet(text: "B+: 88-89%  |  B: 83-87%  |  B-: 80-82%")
            HelpBullet(text: "C+: 78-79%  |  C: 73-77%  |  C-: 70-72%")
            HelpBullet(text: "D+: 68-69%  |  D: 63-67%  |  D-: 60-62%")
            HelpBullet(text: "F: Below 60%")
        }
    }
}

struct AssignmentsHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpHeader(title: "Assignments")
            
            HelpSubheader(title: "Adding Assignments")
            HelpParagraph(text: "There are two ways to add assignments:")
            HelpBullet(text: "From the Assignments view: Click the + button and select a subject")
            HelpBullet(text: "From a Subject detail: Click on a subject card and use the 'Add Assignment' button")
            
            HelpSubheader(title: "Assignment Details")
            HelpParagraph(text: "For each assignment, enter:")
            HelpBullet(text: "Title: Name of the assignment")
            HelpBullet(text: "Type: Daily, Quiz, Test, Project, or Other")
            HelpBullet(text: "Date: When the assignment was completed")
            HelpBullet(text: "Score: Points earned (e.g., 47)")
            HelpBullet(text: "Max Score: Total points possible (e.g., 50)")
            HelpBullet(text: "Notes: Optional additional information")
            
            HelpParagraph(text: "The percentage is automatically calculated from the score and max score.")
            
            HelpSubheader(title: "Viewing Assignments")
            HelpParagraph(text: "Use the filter buttons at the top to view assignments by type (All, Daily, Quiz, Test, Project, Other). Use the search bar to find specific assignments.")
            
            HelpSubheader(title: "Deleting Assignments")
            HelpParagraph(text: "Right-click on an assignment and select 'Delete Assignment' to remove it.")
        }
    }
}

struct BooksHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpHeader(title: "Reading List")
            
            HelpParagraph(text: "Track all books read during the school year. This is perfect for maintaining reading logs and literature requirements.")
            
            HelpSubheader(title: "Adding a Book")
            HelpParagraph(text: "Click the + button and enter:")
            HelpBullet(text: "Title: Name of the book")
            HelpBullet(text: "Author: Book author")
            HelpBullet(text: "Date Read: When the book was completed")
            HelpBullet(text: "Notes: Optional review, summary, or thoughts")
            
            HelpSubheader(title: "Managing Books")
            HelpParagraph(text: "Books are displayed in order by date read (most recent first). Right-click on a book card to delete it.")
        }
    }
}

struct ActivitiesHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpHeader(title: "Activities")
            
            HelpParagraph(text: "Record extracurricular activities, clubs, sports, volunteer work, and other non-academic pursuits.")
            
            HelpSubheader(title: "Adding an Activity")
            HelpBullet(text: "Activity Description: What the student did")
            HelpBullet(text: "Role: Optional leadership position or participation level")
            HelpBullet(text: "Date: When the activity took place")
            
            HelpParagraph(text: "Activities are useful for college applications, portfolios, and tracking well-rounded development.")
        }
    }
}

struct FieldTripsHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpHeader(title: "Field Trips")
            
            HelpParagraph(text: "Document educational field trips, museum visits, historical sites, and other learning experiences outside the classroom.")
            
            HelpSubheader(title: "Recording a Field Trip")
            HelpBullet(text: "Trip Description: What was visited or experienced")
            HelpBullet(text: "Location: Where the trip took place")
            HelpBullet(text: "Date: When it occurred")
            HelpBullet(text: "Notes: Learning outcomes, observations, or reflections")
            
            HelpTip(text: "Field trips are great for demonstrating hands-on learning and can be included in portfolios or transcripts.")
        }
    }
}

struct CoursesHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpHeader(title: "Course Descriptions")
            
            HelpParagraph(text: "Create formal course descriptions for transcript purposes. This is especially useful for high school level work that will be used for college applications.")
            
            HelpSubheader(title: "Creating a Course Description")
            HelpBullet(text: "Title: Official course name")
            HelpBullet(text: "Description: Detailed explanation of what was covered")
            HelpBullet(text: "Resources: Textbooks, curricula, and materials used")
            
            HelpParagraph(text: "Course descriptions help document the rigor and content of homeschool courses for college admissions offices.")
        }
    }
}

struct ReportsHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpHeader(title: "Reports")
            
            HelpParagraph(text: "Generate comprehensive reports showing student performance, grades, and achievements.")
            
            HelpSubheader(title: "Report Contents")
            HelpBullet(text: "Overall GPA calculated from all subjects")
            HelpBullet(text: "Total credits earned")
            HelpBullet(text: "Detailed grade breakdown by subject")
            HelpBullet(text: "Letter grades and percentages")
            HelpBullet(text: "Complete grade scale reference")
            
            HelpSubheader(title: "Exporting Reports")
            HelpParagraph(text: "Use the 'Export as PDF' button to save a professional report that can be printed or shared. Reports are formatted for official record-keeping and transcript purposes.")
        }
    }
}

struct TipsHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpHeader(title: "Tips & Tricks")
            
            HelpTip(text: "Right-click (or Control+click) on most items to see additional options like Delete.")
            
            HelpTip(text: "Use colors consistently across subjects to make them easy to identify at a glance.")
            
            HelpTip(text: "Set up realistic grade weights that reflect your homeschool priorities. You can adjust these per subject.")
            
            HelpTip(text: "Add assignments regularly to see accurate grade calculations throughout the year.")
            
            HelpTip(text: "Use the Dashboard for a quick overview and the Reports view for formal documentation.")
            
            HelpTip(text: "Keep notes on assignments, books, and field trips to help with year-end reviews and portfolio creation.")
            
            HelpTip(text: "You can have different school years for each student, making it easy to track siblings at different grade levels.")
            
            HelpWarning(text: "Always back up your data! Currently, all data is stored locally on your computer.")
            
            HelpSubheader(title: "Keyboard Shortcuts")
            HelpBullet(text: "⌘ + N: New Student")
            HelpBullet(text: "⌘ + F: Search (in Assignments view)")
            HelpBullet(text: "⌘ + W: Close Window")
            HelpBullet(text: "⌘ + Q: Quit Application")
        }
    }
}

// MARK: - Help View Components

struct HelpHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 32, weight: .bold))
            .padding(.bottom, 8)
    }
}

struct HelpSubheader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.semibold)
            .padding(.top, 8)
    }
}

struct HelpParagraph: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.primary)
    }
}

struct HelpBullet: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .fontWeight(.bold)
            Text(text)
                .font(.body)
        }
        .padding(.leading, 8)
    }
}

struct HelpStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(.blue.gradient))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct HelpTip: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
                .font(.title3)
            
            Text(text)
                .font(.body)
        }
        .padding()
        .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

struct HelpWarning: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.title3)
            
            Text(text)
                .font(.body)
        }
        .padding()
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Student.self, SchoolYear.self], inMemory: true)
}
