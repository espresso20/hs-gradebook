import SwiftUI
import SwiftData
import Charts
import AppKit

// MARK: - Books View
struct BooksView: View {
    @Environment(\.modelContext) private var modelContext
    let schoolYear: SchoolYear
    @State private var showingNewBook = false
    @State private var bookToDelete: Book?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary Card
                HStack(spacing: 30) {
                    VStack(alignment: .leading) {
                        Text("\(schoolYear.books.count)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.purple.gradient)
                        Text("Books Read")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.purple.gradient.opacity(0.3))
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                // Books List
                ForEach(schoolYear.books.sorted(by: { $0.dateRead > $1.dateRead })) { book in
                    BookCard(book: book)
                        .contextMenu {
                            Button(role: .destructive) {
                                bookToDelete = book
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Book", systemImage: "trash")
                            }
                        }
                }
                
                Button(action: { showingNewBook = true }) {
                    Label("Add Book", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple.gradient.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle("Reading List")
        .toolbar {
            ToolbarItem {
                Button(action: { showingNewBook = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewBook) {
            NewBookView(schoolYear: schoolYear)
        }
        .alert("Delete Book?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let book = bookToDelete {
                    modelContext.delete(book)
                    bookToDelete = nil
                }
            }
        } message: {
            if let book = bookToDelete {
                Text("Are you sure you want to delete \"\(book.title)\" by \(book.author)? This action cannot be undone.")
            }
        }
    }
}

struct BookCard: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "book.fill")
                .font(.largeTitle)
                .foregroundStyle(.purple.gradient)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.headline)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(book.dateRead, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !book.notes.isEmpty {
                    Text(book.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct NewBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let schoolYear: SchoolYear
    
    @State private var title = ""
    @State private var author = ""
    @State private var dateRead = Date()
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Book Information") {
                    TextField("Title", text: $title)
                        .characterLimit(CharacterLimits.title, text: $title)
                    TextField("Author", text: $author)
                        .characterLimit(CharacterLimits.title, text: $author)
                    DatePicker("Date Finished", selection: $dateRead, displayedComponents: .date)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .characterLimit(CharacterLimits.notes, text: $notes)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Book")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let book = Book(title: title, author: author, dateRead: dateRead, notes: notes)
                        book.schoolYear = schoolYear
                        modelContext.insert(book)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .frame(minWidth: 450, idealWidth: 500, maxWidth: 600, minHeight: 400, idealHeight: 450, maxHeight: 600)
        .padding()
    }
}

// MARK: - Activities View
struct ActivitiesView: View {
    @Environment(\.modelContext) private var modelContext
    let schoolYear: SchoolYear
    @State private var showingNewActivity = false
    @State private var activityToDelete: Activity?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(schoolYear.activities.sorted(by: { $0.date > $1.date })) { activity in
                    ActivityCard(activity: activity)
                        .contextMenu {
                            Button(role: .destructive) {
                                activityToDelete = activity
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Activity", systemImage: "trash")
                            }
                        }
                }
                
                Button(action: { showingNewActivity = true }) {
                    Label("Add Activity", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange.gradient.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle("Activities")
        .toolbar {
            ToolbarItem {
                Button(action: { showingNewActivity = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewActivity) {
            NewActivityView(schoolYear: schoolYear)
        }
        .alert("Delete Activity?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let activity = activityToDelete {
                    modelContext.delete(activity)
                    activityToDelete = nil
                }
            }
        } message: {
            if let activity = activityToDelete {
                Text("Are you sure you want to delete \"\(activity.activityDescription)\"? This action cannot be undone.")
            }
        }
    }
}

struct ActivityCard: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "figure.run.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange.gradient)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(activity.activityDescription)
                    .font(.headline)
                if !activity.role.isEmpty {
                    Text(activity.role)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(activity.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct NewActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let schoolYear: SchoolYear
    
    @State private var activityDescription = ""
    @State private var role = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Activity Details") {
                    TextField("Description", text: $activityDescription)
                        .characterLimit(CharacterLimits.description, text: $activityDescription)
                    TextField("Role", text: $role)
                        .characterLimit(CharacterLimits.title, text: $role)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Activity")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let activity = Activity(date: date, activityDescription: activityDescription, role: role)
                        activity.schoolYear = schoolYear
                        modelContext.insert(activity)
                        dismiss()
                    }
                    .disabled(activityDescription.isEmpty)
                }
            }
        }
        .frame(minWidth: 450, idealWidth: 500, maxWidth: 600, minHeight: 300, idealHeight: 350, maxHeight: 500)
        .padding()
    }
}

// MARK: - Field Trips View
struct FieldTripsView: View {
    @Environment(\.modelContext) private var modelContext
    let schoolYear: SchoolYear
    @State private var showingNewTrip = false
    @State private var tripToDelete: FieldTrip?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(schoolYear.fieldTrips.sorted(by: { $0.date > $1.date })) { trip in
                    FieldTripCard(trip: trip)
                        .contextMenu {
                            Button(role: .destructive) {
                                tripToDelete = trip
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Field Trip", systemImage: "trash")
                            }
                        }
                }
                
                Button(action: { showingNewTrip = true }) {
                    Label("Add Field Trip", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green.gradient.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle("Field Trips")
        .toolbar {
            ToolbarItem {
                Button(action: { showingNewTrip = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewTrip) {
            NewFieldTripView(schoolYear: schoolYear)
        }
        .alert("Delete Field Trip?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let trip = tripToDelete {
                    modelContext.delete(trip)
                    tripToDelete = nil
                }
            }
        } message: {
            if let trip = tripToDelete {
                Text("Are you sure you want to delete \"\(trip.tripDescription)\"? This action cannot be undone.")
            }
        }
    }
}

struct FieldTripCard: View {
    let trip: FieldTrip
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "bus.fill")
                .font(.largeTitle)
                .foregroundStyle(.green.gradient)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(trip.tripDescription)
                    .font(.headline)
                if !trip.location.isEmpty {
                    Label(trip.location, systemImage: "mappin.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(trip.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !trip.notes.isEmpty {
                    Text(trip.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct NewFieldTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let schoolYear: SchoolYear
    
    @State private var tripDescription = ""
    @State private var location = ""
    @State private var date = Date()
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Field Trip Details") {
                    TextField("Description", text: $tripDescription)
                        .characterLimit(CharacterLimits.description, text: $tripDescription)
                    TextField("Location", text: $location)
                        .characterLimit(CharacterLimits.title, text: $location)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                        .characterLimit(CharacterLimits.notes, text: $notes)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Field Trip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trip = FieldTrip(date: date, tripDescription: tripDescription, location: location, notes: notes)
                        trip.schoolYear = schoolYear
                        modelContext.insert(trip)
                        dismiss()
                    }
                    .disabled(tripDescription.isEmpty)
                }
            }
        }
        .frame(minWidth: 450, idealWidth: 500, maxWidth: 600, minHeight: 400, idealHeight: 450, maxHeight: 600)
        .padding()
    }
}

// MARK: - Courses View
struct CoursesView: View {
    @Environment(\.modelContext) private var modelContext
    let schoolYear: SchoolYear
    @State private var showingNewCourse = false
    @State private var courseToDelete: Course?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(schoolYear.courses) { course in
                    CourseCard(course: course)
                        .contextMenu {
                            Button(role: .destructive) {
                                courseToDelete = course
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Course", systemImage: "trash")
                            }
                        }
                }
                
                Button(action: { showingNewCourse = true }) {
                    Label("Add Course", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.indigo.gradient.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle("Course Descriptions")
        .toolbar {
            ToolbarItem {
                Button(action: { showingNewCourse = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewCourse) {
            NewCourseView(schoolYear: schoolYear)
        }
        .alert("Delete Course?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let course = courseToDelete {
                    modelContext.delete(course)
                    courseToDelete = nil
                }
            }
        } message: {
            if let course = courseToDelete {
                Text("Are you sure you want to delete \"\(course.title)\"? This action cannot be undone.")
            }
        }
    }
}

struct CourseCard: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "graduationcap.fill")
                    .font(.title2)
                    .foregroundStyle(.indigo.gradient)
                
                Text(course.title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            if !course.courseDescription.isEmpty {
                Text(course.courseDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            if !course.resources.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resources")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text(course.resources)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct NewCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let schoolYear: SchoolYear
    
    @State private var title = ""
    @State private var courseDescription = ""
    @State private var resources = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Course Information") {
                    TextField("Course Title", text: $title)
                        .characterLimit(CharacterLimits.title, text: $title)
                }
                
                Section("Description") {
                    TextEditor(text: $courseDescription)
                        .frame(height: 100)
                        .characterLimit(CharacterLimits.description, text: $courseDescription)
                }
                
                Section("Resources Used") {
                    TextEditor(text: $resources)
                        .frame(height: 80)
                        .characterLimit(CharacterLimits.notes, text: $resources)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Course")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let course = Course(title: title, courseDescription: courseDescription, resources: resources)
                        course.schoolYear = schoolYear
                        modelContext.insert(course)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .frame(minWidth: 500, idealWidth: 550, maxWidth: 650, minHeight: 450, idealHeight: 500, maxHeight: 700)
        .padding()
    }
}

// MARK: - Reports View
struct ReportsView: View {
    let student: Student
    let schoolYear: SchoolYear
    @State private var showingExportSuccess = false
    @State private var exportError: String?
    @AppStorage("gradingScaleType") private var gradingScaleType: String = GradingScaleType.granular.rawValue
    
    private var currentGradingScale: [GradeScaleItem] {
        let scaleType = GradingScaleType(rawValue: gradingScaleType) ?? .granular
        return GradingScaleDefinition.scale(for: scaleType)
    }
    
    var overallGPA: Double {
        let grades = schoolYear.subjects.map { $0.weightedGrade }
        guard !grades.isEmpty else { return 0 }
        return grades.reduce(0, +) / Double(grades.count)
    }
    
    var totalCredits: Double {
        schoolYear.subjects.reduce(0) { $0 + $1.credits }
    }
    
    func exportToPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(student.name) - \(schoolYear.year) Grade Report.pdf"
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.title = "Export Grade Report as PDF"
        panel.message = "Choose a location to save the grade report"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let renderer = ImageRenderer(content: ReportContentView(
                    student: student,
                    schoolYear: schoolYear,
                    overallGPA: overallGPA,
                    totalCredits: totalCredits
                ))
                
                renderer.render { size, renderer in
                    var mediaBox = CGRect(origin: .zero, size: size)
                    
                    guard let consumer = CGDataConsumer(url: url as CFURL),
                          let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
                        exportError = "Failed to create PDF context"
                        return
                    }
                    
                    pdfContext.beginPDFPage(nil)
                    renderer(pdfContext)
                    pdfContext.endPDFPage()
                    pdfContext.closePDF()
                    
                    DispatchQueue.main.async {
                        showingExportSuccess = true
                    }
                }
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Report Header
                VStack(alignment: .leading, spacing: 16) {
                    Text("Grade Report")
                        .font(.system(size: 40, weight: .bold))
                    
                    Grid(alignment: .leading, horizontalSpacing: 40, verticalSpacing: 12) {
                        GridRow {
                            Text("Student:")
                                .foregroundStyle(.secondary)
                            Text(student.name)
                                .fontWeight(.semibold)
                        }
                        
                        GridRow {
                            Text("School Year:")
                                .foregroundStyle(.secondary)
                            Text(schoolYear.year)
                                .fontWeight(.semibold)
                        }
                        
                        GridRow {
                            Text("School:")
                                .foregroundStyle(.secondary)
                            Text(student.school)
                                .fontWeight(.semibold)
                        }
                        
                        GridRow {
                            Text("Total School Days:")
                                .foregroundStyle(.secondary)
                            Text("\(schoolYear.totalSchoolDays)")
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                // GPA and Credits
                HStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("\(overallGPA, specifier: "%.1f")")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.blue.gradient)
                        Text("Overall GPA")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    VStack(spacing: 8) {
                        Text("\(totalCredits, specifier: "%.1f")")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.green.gradient)
                        Text("Total Credits")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                
                // Subject Grades Table
                VStack(alignment: .leading, spacing: 16) {
                    Text("Courses & Grades")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                        GridRow {
                            Text("Course")
                                .fontWeight(.semibold)
                            Text("Credits")
                                .fontWeight(.semibold)
                                .gridColumnAlignment(.trailing)
                            Text("Grade")
                                .fontWeight(.semibold)
                                .gridColumnAlignment(.trailing)
                            Text("Letter")
                                .fontWeight(.semibold)
                                .gridColumnAlignment(.trailing)
                        }
                        .foregroundStyle(.secondary)
                        
                        Divider()
                        
                        ForEach(schoolYear.subjects.sorted(by: { $0.order < $1.order })) { subject in
                            GridRow {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(hex: subject.color) ?? .blue)
                                        .frame(width: 8, height: 8)
                                    Text(subject.name)
                                }
                                Text("\(subject.credits, specifier: "%.1f")")
                                    .gridColumnAlignment(.trailing)
                                Text("\(subject.weightedGrade, specifier: "%.1f")%")
                                    .gridColumnAlignment(.trailing)
                                Text(subject.letterGrade)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color(hex: subject.color) ?? .blue)
                                    .gridColumnAlignment(.trailing)
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                // Grading Scale Reference
                VStack(alignment: .leading, spacing: 12) {
                    Text("Grading Scale")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(currentGradingScale) { grade in
                            HStack {
                                Text(grade.letter)
                                    .fontWeight(.semibold)
                                    .frame(width: 40, alignment: .leading)
                                Text(grade.range)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                // Export Button
                Button(action: exportToPDF) {
                    Label("Export as PDF", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle("Grade Report")
        .alert("Export Successful", isPresented: $showingExportSuccess) {
            Button("OK") { }
        } message: {
            Text("Grade report has been exported as PDF.")
        }
        .alert("Export Failed", isPresented: .constant(exportError != nil)) {
            Button("OK") { exportError = nil }
        } message: {
            Text(exportError ?? "Unknown error")
        }
    }
}

// MARK: - Report Content View (for PDF export)
struct ReportContentView: View {
    let student: Student
    let schoolYear: SchoolYear
    let overallGPA: Double
    let totalCredits: Double
    
    private var currentGradingScale: [GradeScaleItem] {
        let scaleType = UserDefaults.standard.gradingScaleType
        return GradingScaleDefinition.scale(for: scaleType)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Text("GRADE REPORT")
                    .font(.system(size: 32, weight: .bold))
                Text("Academic Transcript")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            
            Divider()
            
            // Student Information
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Student Name:")
                        .fontWeight(.semibold)
                        .frame(width: 150, alignment: .leading)
                    Text(student.name)
                }
                HStack {
                    Text("Grade Level:")
                        .fontWeight(.semibold)
                        .frame(width: 150, alignment: .leading)
                    Text(student.grade.isEmpty ? "N/A" : student.grade)
                }
                HStack {
                    Text("School:")
                        .fontWeight(.semibold)
                        .frame(width: 150, alignment: .leading)
                    Text(student.school.isEmpty ? "N/A" : student.school)
                }
                HStack {
                    Text("School Year:")
                        .fontWeight(.semibold)
                        .frame(width: 150, alignment: .leading)
                    Text(schoolYear.year)
                }
                HStack {
                    Text("Total School Days:")
                        .fontWeight(.semibold)
                        .frame(width: 150, alignment: .leading)
                    Text("\(schoolYear.totalSchoolDays)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)
            
            Divider()
            
            // GPA and Credits
            HStack(spacing: 60) {
                VStack(spacing: 4) {
                    Text("Overall GPA")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("\(overallGPA, specifier: "%.2f")")
                        .font(.system(size: 36, weight: .bold))
                }
                
                VStack(spacing: 4) {
                    Text("Total Credits")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("\(totalCredits, specifier: "%.1f")")
                        .font(.system(size: 36, weight: .bold))
                }
            }
            .padding(.vertical, 20)
            
            Divider()
            
            // Course Grades
            VStack(alignment: .leading, spacing: 16) {
                Text("COURSES & GRADES")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                    GridRow {
                        Text("Course Name")
                            .fontWeight(.bold)
                        Text("Credits")
                            .fontWeight(.bold)
                            .gridColumnAlignment(.trailing)
                        Text("Percentage")
                            .fontWeight(.bold)
                            .gridColumnAlignment(.trailing)
                        Text("Letter Grade")
                            .fontWeight(.bold)
                            .gridColumnAlignment(.center)
                    }
                    .font(.headline)
                    
                    Divider()
                    
                    ForEach(schoolYear.subjects.sorted(by: { $0.order < $1.order })) { subject in
                        GridRow {
                            Text(subject.name)
                            Text("\(subject.credits, specifier: "%.1f")")
                                .gridColumnAlignment(.trailing)
                            Text("\(subject.weightedGrade, specifier: "%.1f")%")
                                .gridColumnAlignment(.trailing)
                            Text(subject.letterGrade)
                                .fontWeight(.semibold)
                                .gridColumnAlignment(.center)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)
            
            Divider()
            
            // Grading Scale
            VStack(alignment: .leading, spacing: 12) {
                Text("GRADING SCALE")
                    .font(.headline)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(currentGradingScale) { grade in
                        HStack {
                            Text(grade.letter)
                                .fontWeight(.semibold)
                                .frame(width: 30, alignment: .leading)
                            Text("=")
                            Text(grade.range)
                        }
                        .font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Footer
            VStack(spacing: 4) {
                Text("Generated: \(Date().formatted(date: .long, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Gradebook Plus")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 20)
        }
        .frame(width: 612, height: 792) // US Letter size in points (8.5" x 11")
        .background(Color.white)
    }
}

// Note: Grading scale is now dynamically loaded from GradingScale.swift
// based on user's preference (granular vs simple)

#Preview {
    ReportsView(student: Student(name: "John Doe"), schoolYear: SchoolYear(year: "2024-2025"))
        .modelContainer(for: [Student.self], inMemory: true)
}
