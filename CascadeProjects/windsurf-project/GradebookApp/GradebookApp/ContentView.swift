import SwiftUI
import SwiftData
import Charts

// MARK: - Theme Settings
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var students: [Student]
    @State private var selectedStudent: Student?
    @State private var selectedSchoolYear: SchoolYear?
    @State private var selectedView: NavigationItem = .dashboard
    @State private var showingNewStudentSheet = false
    @State private var showingNewSchoolYearSheet = false
    @State private var showingSettings = false
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @EnvironmentObject var backupManager: BackupManager
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView(
                students: students,
                selectedStudent: $selectedStudent,
                selectedSchoolYear: $selectedSchoolYear,
                selectedView: $selectedView,
                showingNewStudentSheet: $showingNewStudentSheet,
                showingNewSchoolYearSheet: $showingNewSchoolYearSheet,
                appTheme: $appTheme,
                showingSettings: $showingSettings
            )
        } detail: {
            // Main content area
            if selectedView == .help {
                HelpView()
            } else if let student = selectedStudent, let schoolYear = selectedSchoolYear {
                MainContentView(
                    student: student,
                    schoolYear: schoolYear,
                    selectedView: selectedView
                )
            } else {
                WelcomeView(showingNewStudentSheet: $showingNewStudentSheet)
            }
        }
        .preferredColorScheme(appTheme.colorScheme)
        .sheet(isPresented: $showingNewStudentSheet) {
            NewStudentView()
        }
        .sheet(isPresented: $showingNewSchoolYearSheet) {
            if let student = selectedStudent {
                NewSchoolYearView(student: student)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(backupManager: backupManager, modelContext: modelContext, isPresented: $showingSettings)
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
    case calendar = "Calendar"
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
        case .calendar: return "calendar"
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
    @Binding var appTheme: AppTheme
    @Binding var showingSettings: Bool
    @State private var expandedStudentId: UUID?
    @State private var studentToDelete: Student?
    @State private var showingDeleteStudentConfirmation = false
    @State private var schoolYearToDelete: SchoolYear?
    @State private var showingDeleteSchoolYearConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
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
                
                if selectedStudent != nil && selectedSchoolYear != nil {
                    Section("Navigation") {
                        ForEach(NavigationItem.allCases.filter { $0 != .help }, id: \.self) { item in
                            Button(action: {
                                selectedView = item
                            }) {
                                HStack {
                                    Label(item.rawValue, systemImage: item.icon)
                                    Spacer()
                                    if selectedView == item {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(selectedView == item ? Color.blue.opacity(0.2) : Color.clear)
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
            }
            .listStyle(.sidebar)
            
            // Bottom toolbar with Settings, Theme, and Help buttons
            HStack(spacing: 0) {
                // Settings button
                Button(action: { 
                    showingSettings = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 11))
                        Text("Settings")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 20)
                
                // Theme switcher
                Menu {
                    ForEach(AppTheme.allCases) { theme in
                        Button(action: {
                            appTheme = theme
                        }) {
                            HStack {
                                Image(systemName: theme.icon)
                                Text(theme.rawValue)
                                if appTheme == theme {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: appTheme.icon)
                            .font(.system(size: 11))
                        Text("Theme")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .menuStyle(.borderlessButton)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
                
                Divider()
                    .frame(height: 20)
                
                // Help button
                Button(action: { 
                    selectedView = .help 
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 11))
                        Text("Help")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 28)
            .background(Color(nsColor: .controlBackgroundColor))
            .overlay(Rectangle().frame(height: 0.5).foregroundStyle(Color(nsColor: .separatorColor)), alignment: .top)
        }
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
            case .calendar:
                CalendarView(schoolYear: schoolYear)
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
                // Help is handled separately in ContentView, will never reach here
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Calendar Event Model
enum CalendarEventType {
    case assignment(Assignment, Subject)
    case activity(Activity)
    case fieldTrip(FieldTrip)
    case book(Book)
    
    var displayText: String {
        switch self {
        case .assignment(let assignment, _):
            return "📝 \(assignment.title)"
        case .activity(let activity):
            return "🎯 \(activity.activityDescription)"
        case .fieldTrip(let trip):
            return "🚌 \(trip.tripDescription)"
        case .book(let book):
            return "📚 \(book.title)"
        }
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    let schoolYear: SchoolYear
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var selectedSubject: Subject?
    @State private var selectedBook: Book?
    @State private var selectedActivity: Activity?
    @State private var selectedFieldTrip: FieldTrip?
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate < monthInterval.end {
            let monthStart = monthInterval.start
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) ?? monthStart
            
            if currentDate >= monthStart && currentDate <= monthEnd {
                days.append(currentDate)
            } else {
                days.append(nil)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private func eventsOn(date: Date) -> [CalendarEventType] {
        var events: [CalendarEventType] = []
        let calendar = Calendar.current
        
        // Check assignments
        for subject in schoolYear.subjects {
            for assignment in subject.assignments {
                if calendar.isDate(assignment.date, inSameDayAs: date) {
                    events.append(.assignment(assignment, subject))
                }
            }
        }
        
        // Check activities
        for activity in schoolYear.activities {
            if calendar.isDate(activity.date, inSameDayAs: date) {
                events.append(.activity(activity))
            }
        }
        
        // Check field trips
        for trip in schoolYear.fieldTrips {
            if calendar.isDate(trip.date, inSameDayAs: date) {
                events.append(.fieldTrip(trip))
            }
        }
        
        // Check books finished
        for book in schoolYear.books {
            if calendar.isDate(book.dateRead, inSameDayAs: date) {
                events.append(.book(book))
            }
        }
        
        return events
    }
    
    private func handleEventTap(_ event: CalendarEventType) {
        switch event {
        case .assignment(_, let subject):
            selectedSubject = subject
        case .activity(let activity):
            selectedActivity = activity
        case .fieldTrip(let trip):
            selectedFieldTrip = trip
        case .book(let book):
            selectedBook = book
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with month navigation
                HStack {
                    Button(action: {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text(monthYearString)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    
                    Button("Today") {
                        currentMonth = Date()
                        selectedDate = Date()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                // Weekday headers
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
                    ForEach(0..<daysInMonth().count, id: \.self) { index in
                        if let date = daysInMonth()[index] {
                            DayCell(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDateInToday(date),
                                eventCount: eventsOn(date: date).count
                            ) {
                                selectedDate = date
                            }
                        } else {
                            Color.clear
                                .frame(minHeight: 70, maxHeight: 90)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical)
                
                // Selected date events section - always visible
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected Date")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(selectedDate, style: .date)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        if !eventsOn(date: selectedDate).isEmpty {
                            Text("\(eventsOn(date: selectedDate).count) event\(eventsOn(date: selectedDate).count == 1 ? "" : "s")")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.2), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    if eventsOn(date: selectedDate).isEmpty {
                        HStack {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("No events on this day")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    } else {
                        ForEach(Array(eventsOn(date: selectedDate).enumerated()), id: \.offset) { index, event in
                            Button(action: {
                                handleEventTap(event)
                            }) {
                                HStack(spacing: 12) {
                                    Text(event.displayText)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    
                                    // Show indicator - all events are clickable now
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("Calendar")
        .sheet(item: $selectedSubject) { subject in
            SubjectDetailView(subject: subject)
        }
        .sheet(item: $selectedBook) { book in
            BookDetailSheet(book: book)
        }
        .sheet(item: $selectedActivity) { activity in
            ActivityDetailSheet(activity: activity)
        }
        .sheet(item: $selectedFieldTrip) { trip in
            FieldTripDetailSheet(trip: trip)
        }
    }
}

// MARK: - Detail Sheets for Calendar Events

struct BookDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let book: Book
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Book Information") {
                    LabeledContent("Title", value: book.title)
                    LabeledContent("Author", value: book.author)
                    LabeledContent("Date Finished") {
                        Text(book.dateRead, style: .date)
                    }
                }
                
                if !book.notes.isEmpty {
                    Section("Notes") {
                        Text(book.notes)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Book Details")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(width: 450, height: 350)
    }
}

struct ActivityDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let activity: Activity
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Activity Information") {
                    LabeledContent("Description", value: activity.activityDescription)
                    LabeledContent("Role", value: activity.role)
                    LabeledContent("Date") {
                        Text(activity.date, style: .date)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Activity Details")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(width: 450, height: 300)
    }
}

struct FieldTripDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let trip: FieldTrip
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Field Trip Information") {
                    LabeledContent("Description", value: trip.tripDescription)
                    LabeledContent("Location", value: trip.location)
                    LabeledContent("Date") {
                        Text(trip.date, style: .date)
                    }
                }
                
                if !trip.notes.isEmpty {
                    Section("Notes") {
                        Text(trip.notes)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Field Trip Details")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(width: 450, height: 350)
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let eventCount: Int
    let action: () -> Void
    
    @State private var isHovering = false
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(dayNumber)
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundStyle(isSelected ? .white : (isToday ? .blue : .primary))
            
            if eventCount > 0 {
                HStack(spacing: 3) {
                    ForEach(0..<min(eventCount, 3), id: \.self) { _ in
                        Circle()
                            .fill(isSelected ? .white : .blue)
                            .frame(width: 5, height: 5)
                    }
                }
            } else {
                Spacer()
                    .frame(height: 5)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 70, maxHeight: 90)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.15) : (isHovering ? Color.gray.opacity(0.1) : Color.clear)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .onHover { hovering in
            isHovering = hovering
        }
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
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 9, to: Date()) ?? Date()
    @State private var totalDays = 180
    @State private var useCustomName = false
    @State private var customYear = ""
    
    private var autoGeneratedYear: String {
        let calendar = Calendar.current
        let startYear = calendar.component(.year, from: startDate)
        let endYear = calendar.component(.year, from: endDate)
        
        if startYear == endYear {
            return "\(startYear)"
        } else {
            return "\(startYear)-\(endYear)"
        }
    }
    
    private var finalYearName: String {
        useCustomName && !customYear.isEmpty ? customYear : autoGeneratedYear
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("School Year Information") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Custom Year Name", isOn: $useCustomName)
                        
                        if useCustomName {
                            TextField("e.g., 2024-2025", text: $customYear)
                                .characterLimit(CharacterLimits.shortIdentifier, text: $customYear)
                        } else {
                            HStack {
                                Text("Year Name:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(autoGeneratedYear)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    
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
                            year: finalYearName,
                            startDate: startDate,
                            endDate: endDate,
                            totalSchoolDays: totalDays
                        )
                        schoolYear.student = student
                        modelContext.insert(schoolYear)
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 450, height: 420)
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
    case compatibility = "Compatibility"
    case students = "Managing Students"
    case schoolYears = "School Years"
    case subjects = "Subjects & Grading"
    case assignments = "Assignments"
    case calendar = "Calendar"
    case books = "Reading List"
    case activities = "Activities"
    case fieldTrips = "Field Trips"
    case courses = "Course Descriptions"
    case reports = "Reports"
    case gradingScales = "Grading Scales"
    case tips = "Tips & Tricks"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .gettingStarted: return "flag.fill"
        case .compatibility: return "checkmark.shield.fill"
        case .students: return "person.fill"
        case .schoolYears: return "calendar.badge.clock"
        case .subjects: return "book.fill"
        case .assignments: return "doc.text.fill"
        case .calendar: return "calendar"
        case .books: return "books.vertical.fill"
        case .activities: return "figure.run"
        case .fieldTrips: return "bus.fill"
        case .courses: return "graduationcap.fill"
        case .reports: return "chart.line.uptrend.xyaxis"
        case .gradingScales: return "percent"
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
        case .compatibility:
            CompatibilityHelpContent()
        case .students:
            StudentsHelpContent()
        case .schoolYears:
            SchoolYearsHelpContent()
        case .subjects:
            SubjectsHelpContent()
        case .assignments:
            AssignmentsHelpContent()
        case .calendar:
            CalendarHelpContent()
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
        case .gradingScales:
            GradingScalesHelpContent()
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
            
            VStack(alignment: .leading, spacing: 4) {
                HelpParagraph(text: "Gradebook Plus is a comprehensive homeschool grade tracking application designed to help you manage students, subjects, assignments, and generate detailed reports.")
                
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                
                Text("Written by Adam Roffler")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
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

struct CompatibilityHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpHeader(title: "System Requirements & Compatibility")
            
            HelpSubheader(title: "Minimum Requirements")
            HelpParagraph(text: "Gradebook Plus requires macOS 14.0 (Sonoma) or later to run.")
            
            HelpSubheader(title: "Supported macOS Versions")
            HelpBullet(text: "macOS 14.0 Sonoma (2023) ✅")
            HelpBullet(text: "macOS 15.0 Sequoia (2024) ✅")
            HelpBullet(text: "Future macOS versions ✅")
            
            HelpSubheader(title: "Compatible Mac Models")
            HelpParagraph(text: "Any Mac that can run macOS Sonoma or later is compatible, including:")
            HelpBullet(text: "2019 Mac Pro and later")
            HelpBullet(text: "2018 MacBook Air and later")
            HelpBullet(text: "2018 Mac mini and later")
            HelpBullet(text: "2018 MacBook Pro and later")
            HelpBullet(text: "2019 iMac and later")
            HelpBullet(text: "2022 Mac Studio and later")
            HelpBullet(text: "All Macs with Apple Silicon (M1, M2, M3, M4)")
            
            HelpSubheader(title: "Older macOS Versions")
            HelpParagraph(text: "Unfortunately, macOS 13 (Ventura) and earlier versions are not supported.")
            
            HelpTip(text: "If your Mac supports macOS Sonoma, you can upgrade for free from System Settings → General → Software Update.")
            
            HelpSubheader(title: "Data Storage")
            HelpParagraph(text: "All data is stored locally on your Mac using SwiftData. Your gradebook information is private and never leaves your computer.")
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
            HelpParagraph(text: "Expand a student in the sidebar and click 'Add School Year'. Select start and end dates, and the year name is automatically generated!")
            
            HelpSubheader(title: "Smart Year Names")
            HelpParagraph(text: "Year names are auto-generated from your dates:")
            HelpBullet(text: "Aug 2024 → June 2025 = '2024-2025'")
            HelpBullet(text: "Jan 2025 → Dec 2025 = '2025'")
            HelpBullet(text: "Toggle 'Custom Year Name' if you want something different")
            
            HelpSubheader(title: "School Days")
            HelpParagraph(text: "Set the total number of school days (default: 180). This helps track completion progress throughout the year.")
            
            HelpSubheader(title: "Managing School Years")
            HelpParagraph(text: "You can have multiple school years per student to track progress over time. Each school year contains its own subjects, assignments, books, activities, field trips, and courses.")
            
            HelpTip(text: "Smart year naming prevents mismatches between year labels and actual date ranges!")
        }
    }
}

struct SubjectsHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpHeader(title: "Subjects & Grading")
            
            HelpSubheader(title: "Creating a Subject")
            HelpParagraph(text: "Navigate to 'Subjects' and click the + button. Enter the subject name, credits, and choose a color for easy identification.")
            
            HelpSubheader(title: "Assignment Type Weights")
            HelpParagraph(text: "Customize which assignment types count toward the final grade:")
            HelpBullet(text: "Daily: Homework and daily work")
            HelpBullet(text: "Quizzes: Short assessments")
            HelpBullet(text: "Tests: Major exams")
            HelpBullet(text: "Projects: Long-term assignments")
            HelpBullet(text: "Other: Additional work")
            
            HelpSubheader(title: "Setting Weights")
            HelpParagraph(text: "Use toggles to enable/disable assignment types and enter exact percentages:")
            HelpBullet(text: "Toggle each type on or off")
            HelpBullet(text: "Type exact percentages in the text fields")
            HelpBullet(text: "Total must equal 100%")
            HelpBullet(text: "Auto-distribution when you enable a new type")
            
            HelpParagraph(text: "You can use as few or as many types as you want! Only tests? Just toggle Tests to 100%.")
            
            HelpSubheader(title: "Editing Subjects")
            HelpParagraph(text: "Click on a subject card to view details. In the detail view:")
            HelpBullet(text: "Click the ✏️ Edit button in the toolbar")
            HelpBullet(text: "Change name, credits, color, or weights")
            HelpBullet(text: "Grades automatically recalculate for all assignments")
            
            HelpSubheader(title: "Character Limits")
            HelpParagraph(text: "Subject names are limited to 50 characters for clean display throughout the app.")
            
            HelpTip(text: "See the 'Grading Scales' help section to learn about switching between granular and simple grading scales!")
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
            HelpBullet(text: "Title: Name of the assignment (max 50 characters)")
            HelpBullet(text: "Type: Only types enabled in the subject appear")
            HelpBullet(text: "Date: When the assignment was completed")
            HelpBullet(text: "Score: Points earned (displayed side-by-side)")
            HelpBullet(text: "Max Score: Total points possible")
            HelpBullet(text: "Notes: Optional notes (max 1000 characters)")
            
            HelpParagraph(text: "The percentage is automatically calculated and color-coded: green (90-100%), blue (80-89%), orange (70-79%), or red (below 70%).")
            
            HelpSubheader(title: "Viewing Assignments")
            HelpParagraph(text: "Use the filter buttons at the top to view assignments by type. Only enabled assignment types appear in the type picker.")
            
            HelpSubheader(title: "Viewing on Calendar")
            HelpParagraph(text: "All assignments appear on the Calendar view on their due dates. Click any assignment in the calendar to jump to its subject details!")
            
            HelpTip(text: "Assignment titles are limited to 50 characters to keep the UI clean and readable.")
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

struct CalendarHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpHeader(title: "Calendar")
            
            HelpParagraph(text: "The Calendar view provides a visual overview of all your school activities, assignments, books finished, field trips, and more.")
            
            HelpSubheader(title: "Viewing the Calendar")
            HelpBullet(text: "Navigate between months using the ◀ ▶ arrows")
            HelpBullet(text: "Click 'Today' to jump to the current date")
            HelpBullet(text: "Blue dots on dates indicate events")
            HelpBullet(text: "Click any date to see events for that day")
            
            HelpSubheader(title: "Calendar Events")
            HelpParagraph(text: "The calendar shows:")
            HelpBullet(text: "📝 Assignments (due dates)")
            HelpBullet(text: "📚 Books (dates finished)")
            HelpBullet(text: "🎯 Activities (activity dates)")
            HelpBullet(text: "🚌 Field Trips (trip dates)")
            
            HelpSubheader(title: "Clickable Events")
            HelpParagraph(text: "All calendar events are clickable! When you click an event:")
            HelpBullet(text: "Assignments → Opens the subject detail view")
            HelpBullet(text: "Books → Shows book details and notes")
            HelpBullet(text: "Activities → Displays activity information")
            HelpBullet(text: "Field Trips → Shows trip details and notes")
            
            HelpTip(text: "Use the calendar to quickly see what's coming up or review what was completed on any day!")
        }
    }
}

struct GradingScalesHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpHeader(title: "Grading Scales")
            
            HelpParagraph(text: "Gradebook Plus supports two grading scales that you can switch between at any time.")
            
            HelpSubheader(title: "Granular Scale (Default)")
            HelpParagraph(text: "This scale includes plus/minus grades for more detailed grading:")
            HelpBullet(text: "A+: 98-100% | A: 93-97% | A-: 90-92%")
            HelpBullet(text: "B+: 88-89% | B: 83-87% | B-: 80-82%")
            HelpBullet(text: "C+: 78-79% | C: 73-77% | C-: 70-72%")
            HelpBullet(text: "D+: 68-69% | D: 63-67% | D-: 60-62%")
            HelpBullet(text: "F: Below 60%")
            
            HelpSubheader(title: "Simple Scale")
            HelpParagraph(text: "This scale uses only letter grades without plus/minus:")
            HelpBullet(text: "A: 90-100%")
            HelpBullet(text: "B: 80-89%")
            HelpBullet(text: "C: 70-79%")
            HelpBullet(text: "D: 60-69%")
            HelpBullet(text: "F: Below 60%")
            
            HelpSubheader(title: "Changing Grading Scales")
            HelpStep(number: 1, title: "Open Settings", description: "Click the ⚙️ Settings button at the bottom of the sidebar")
            HelpStep(number: 2, title: "Select Grading Scale", description: "Click the 'Grading Scale' tab")
            HelpStep(number: 3, title: "Choose Your Scale", description: "Select either Granular or Simple scale")
            
            HelpParagraph(text: "All grades throughout the app (dashboard, subjects, reports, PDFs) will update immediately to use the selected scale.")
            
            HelpTip(text: "Your grading scale choice is saved and persists between app launches.")
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

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var backupManager: BackupManager
    let modelContext: ModelContext
    @Binding var isPresented: Bool
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            
            Divider()
            
            // Tab Selection
            Picker("", selection: $selectedTab) {
                Text("Cloud Backup").tag(0)
                Text("Grading Scale").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            Divider()
            
            // Content
            ScrollView {
                switch selectedTab {
                case 0:
                    BackupSettingsContent(backupManager: backupManager, modelContext: modelContext)
                        .padding()
                case 1:
                    GradingScaleSettingsContent()
                        .padding()
                default:
                    EmptyView()
                }
            }
        }
        .frame(width: 700, height: 600)
    }
}

// MARK: - Backup Settings Content

struct BackupSettingsContent: View {
    @ObservedObject var backupManager: BackupManager
    let modelContext: ModelContext
    @State private var showingGoogleBackupConfirmation = false
    @State private var showingImportConfirmation = false
    @State private var showingImportSuccess = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Description
            Text("Choose how you want to backup your gradebook data. You can use iCloud for automatic sync, Google Drive for manual backups, or keep everything local.")
                .font(.body)
                .foregroundStyle(.secondary)
            
            Divider()
            
            // Backup Method Selection
            VStack(alignment: .leading, spacing: 16) {
                Text("Backup Method")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                ForEach(BackupManager.BackupMethod.allCases, id: \.self) { method in
                    BackupMethodCard(
                        method: method,
                        isSelected: selectedBackupMethod == method,
                        isAvailable: isMethodAvailable(method),
                        action: {
                            selectBackupMethod(method)
                        }
                    )
                }
            }
            
            // Method-specific details
            if selectedBackupMethod == .iCloud && iCloudSyncEnabled {
                iCloudDetailsSection
            } else if selectedBackupMethod == .googleDrive && backupManager.googleDriveConnected {
                googleDriveDetailsSection
            }
        }
        .alert("Backup Saved", isPresented: $showingGoogleBackupConfirmation) {
            Button("OK") { }
        } message: {
            Text("Your gradebook backup has been saved as a JSON file. You can store this file anywhere for safekeeping.")
        }
        .alert("Import Backup - Warning", isPresented: $showingImportConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Import", role: .destructive) {
                Task {
                    let success = await backupManager.importBackup(modelContext: modelContext)
                    if success {
                        showingImportSuccess = true
                    }
                }
            }
        } message: {
            Text("⚠️ This will REPLACE ALL current data with the backup file.\n\nYour existing data will be automatically backed up to:\n~/Documents/GradebookBackups/\n\nThis cannot be undone. Are you sure you want to continue?")
        }
        .alert("Import Successful", isPresented: $showingImportSuccess) {
            Button("OK") { }
        } message: {
            Text("Your backup has been successfully imported!\n\nYour previous data was saved to:\n~/Documents/GradebookBackups/")
        }
    }
    
    // MARK: - Computed Properties
    
    private var selectedBackupMethod: BackupManager.BackupMethod {
        if iCloudSyncEnabled {
            return .iCloud
        } else if backupManager.googleDriveConnected {
            return .googleDrive
        } else {
            return .none
        }
    }
    
    // MARK: - Helper Functions
    
    private func isMethodAvailable(_ method: BackupManager.BackupMethod) -> Bool {
        switch method {
        case .none:
            return true
        case .iCloud:
            return backupManager.iCloudAvailable
        case .googleDrive:
            return true // Always available to connect
        }
    }
    
    private func selectBackupMethod(_ method: BackupManager.BackupMethod) {
        // Disable all first
        iCloudSyncEnabled = false
        backupManager.googleDriveConnected = false
        
        // Enable selected
        switch method {
        case .none:
            break // Keep all disabled
        case .iCloud:
            if backupManager.iCloudAvailable {
                iCloudSyncEnabled = true
                backupManager.selectedBackupMethod = .iCloud
            }
        case .googleDrive:
            backupManager.connectGoogleDrive()
            backupManager.selectedBackupMethod = .googleDrive
        }
    }
    
    // MARK: - Detail Sections
    
    private var iCloudDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
                Text("iCloud sync is active. Your data automatically syncs across all your Apple devices.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var googleDriveDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            if let lastBackup = backupManager.lastGoogleBackup {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.blue)
                    Text("Last backup: \(lastBackup.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await backupManager.backupToGoogleDrive(modelContext: modelContext)
                        // Only show confirmation if no error
                        if backupManager.backupError == nil {
                            showingGoogleBackupConfirmation = true
                        }
                    }
                }) {
                    HStack {
                        if backupManager.isBackingUp {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.up.doc.fill")
                        }
                        Text(backupManager.isBackingUp ? "Exporting..." : "Export Backup")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(backupManager.isBackingUp)
                
                Button(action: {
                    showingImportConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Import Backup")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.bordered)
                .disabled(backupManager.isBackingUp)
            }
            
            if let error = backupManager.backupError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

// MARK: - Backup Method Card

struct BackupMethodCard: View {
    let method: BackupManager.BackupMethod
    let isSelected: Bool
    let isAvailable: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: method.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 50)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(method.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                } else {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable && method != .none)
        .opacity(isAvailable || method == .none ? 1.0 : 0.5)
    }
}

// MARK: - Grading Scale Settings Content

struct GradingScaleSettingsContent: View {
    @AppStorage("gradingScaleType") private var gradingScaleTypeRaw: String = GradingScaleType.granular.rawValue
    
    private var gradingScaleType: GradingScaleType {
        GradingScaleType(rawValue: gradingScaleTypeRaw) ?? .granular
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Description
            Text("Choose how you want grades to be calculated and displayed throughout the app. This affects grade reports, dashboards, and all grade displays.")
                .font(.body)
                .foregroundStyle(.secondary)
            
            Divider()
            
            // Scale Selection
            VStack(alignment: .leading, spacing: 16) {
                Text("Grading Scale Type")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                ForEach(GradingScaleType.allCases, id: \.self) { scaleType in
                    GradingScaleOptionCard(
                        scaleType: scaleType,
                        isSelected: gradingScaleType == scaleType,
                        action: {
                            gradingScaleTypeRaw = scaleType.rawValue
                        }
                    )
                }
            }
            
            Divider()
            
            // Scale Preview
            VStack(alignment: .leading, spacing: 16) {
                Text("Current Scale Preview")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                let currentScale = GradingScaleDefinition.scale(for: gradingScaleType)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(currentScale) { grade in
                        HStack {
                            Text(grade.letter)
                                .fontWeight(.bold)
                                .frame(width: 30, alignment: .leading)
                            Text("=")
                                .foregroundStyle(.secondary)
                            Text(grade.range)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
            }
            
            Divider()
            
            // Info
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
                Text("Changing the grading scale will immediately update all grades throughout the app. Existing percentage scores will be re-evaluated using the new scale.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Grading Scale Option Card

struct GradingScaleOptionCard: View {
    let scaleType: GradingScaleType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: scaleType == .granular ? "list.number" : "list.bullet")
                    .font(.system(size: 32))
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 50)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(scaleType.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(scaleType.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                } else {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Student.self, SchoolYear.self], inMemory: true)
}
