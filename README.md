# Gradebook Plus

A beautiful, modern macOS application for homeschool gradebook management with data entry, grade tracking, and visualization features.

## Features

### 📚 Core Functionality

- **Student Management**: Track multiple students and school years
- **Subject Tracking**: Manage subjects with customizable weighted grading
- **Assignment Management**: Record assignments with different types (Daily, Quizzes, Tests, Projects, Other)
- **Automatic Grade Calculation**: Real-time weighted grade calculations and letter grades

### 📊 Data Visualization

- **Dashboard**: Beautiful overview with statistics and performance charts
- **Grade Charts**: Visual representation of subject performance
- **GPA Tracking**: Automatic GPA calculation based on all subjects
- **Progress Reports**: Comprehensive grade reports with export capability

### 📖 Additional Tracking

- **Reading List**: Track books read with dates and notes
- **Activities Log**: Record extra-curricular activities and roles
- **Field Trips**: Document field trips with locations and descriptions
- **Course Descriptions**: Maintain detailed course descriptions and resources

### 💾 Data Management

- **Local Database**: Uses SwiftData for persistent local storage
- **Fast Performance**: Efficient data querying and updates
- **Future-Ready**: Designed with S3 backup capability in mind

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later

## Building the App

1. Open the project in Xcode:

   ```bash
   cd GradebookApp
   open GradebookApp.xcodeproj
   ```

2. Select your target Mac (My Mac) in the scheme selector

3. Build and run the project:
   - Press `Cmd + R`, or
   - Click the Run button in Xcode toolbar

## Usage

### Getting Started

1. **Create a Student**
   - Click "Create Your First Student" or use `Cmd + N`
   - Enter student name, grade level, and school name

2. **Add a School Year**
   - Select the student in the sidebar
   - Click "Add School Year"
   - Enter the year, start/end dates, and total school days

3. **Create Subjects**
   - Navigate to the "Subjects" view
   - Click "Add New Subject"
   - Set up subject name, credits, color, and grading weights
   - Ensure weights total 100%

4. **Record Assignments**
   - Go to "Assignments" view
   - Click the + button and select a subject
   - Enter assignment details and scores
   - Grades are automatically calculated

### Navigation

The app features a clean sidebar navigation with:

- **Dashboard**: Overview and statistics
- **Subjects**: Manage and view all subjects
- **Assignments**: Track all assignments across subjects
- **Books**: Reading list tracking
- **Activities**: Extra-curricular activities
- **Field Trips**: Educational trips log
- **Courses**: Course descriptions and resources
- **Reports**: Official grade reports

### Grading System

The app uses a standard letter grade system:

- A+ (98-100%), A (93-97%), A- (90-92%)
- B+ (88-89%), B (83-87%), B- (80-82%)
- C+ (78-79%), C (73-77%), C- (70-72%)
- D+ (68-69%), D (63-67%), D- (60-62%)
- F (0-59%)

## Data Model

The app stores all data locally using SwiftData with the following models:

- **Student**: Basic student information
- **SchoolYear**: Academic year details
- **Subject**: Course information with weighted grading
- **Assignment**: Individual assignments with scores
- **Book**: Reading list entries
- **Activity**: Extra-curricular activities
- **FieldTrip**: Educational trips
- **Course**: Course descriptions

All data is stored locally in the app's container and persists between sessions.

## Future Enhancements

### Planned Features

- PDF export for grade reports
- S3 bucket integration for data backup
- Import data from Excel/CSV
- Multiple grading scales support
- Attendance tracking
- GPA calculation customization
- Dark mode optimization
- Print layouts for official transcripts

## Technical Details

### Technology Stack

- **Framework**: SwiftUI
- **Database**: SwiftData (Core Data abstraction)
- **Charts**: Swift Charts
- **Minimum macOS**: 14.0 (Sonoma)
- **Language**: Swift 5.9+

### Architecture

- MVVM pattern with SwiftData integration
- Declarative UI with SwiftUI
- Reactive data binding
- Modular view components

## Spreadsheet Data

This app was designed based on the "FiveJs Gradebook Plus" Excel template structure, providing a modern, native macOS alternative with:

- Better performance
- Native macOS integration
- Real-time calculations
- Beautiful UI/UX
- Local database storage

## Support

For issues or feature requests, please check the documentation or contact support.

## License

Copyright © 2024. All rights reserved.
