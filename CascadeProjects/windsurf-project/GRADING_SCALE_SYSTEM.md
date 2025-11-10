# 📊 Dual Grading Scale System

## ✅ Implemented Features

Your app now has a **complete dual grading scale system** with user-selectable options!

---

## 🎯 Two Grading Scales

### **1. Granular Scale (Default)** ⭐
**13 grade levels with plus/minus variations**

| Letter | Range | Letter | Range | Letter | Range |
|--------|-------|--------|-------|--------|-------|
| **A+** | 98-100 | **B+** | 88-89 | **C+** | 78-79 |
| **A** | 93-97 | **B** | 83-87 | **C** | 73-77 |
| **A-** | 90-92 | **B-** | 80-82 | **C-** | 70-72 |
| | | **D+** | 68-69 | **D** | 63-67 |
| | | **D-** | 60-62 | **F** | 0-59 |

**Best for:** Detailed grade tracking, competitive students, college prep

---

### **2. Simple Scale** 🎯
**5 grade levels without plus/minus**

| Letter | Range |
|--------|-------|
| **A** | 90-100 |
| **B** | 80-89 |
| **C** | 70-79 |
| **D** | 60-69 |
| **F** | 0-59 |

**Best for:** Elementary students, homeschool simplicity, less stress

---

## 🛠️ How to Change Grading Scale

### **Option 1: In Settings (Recommended)**

1. Click **⚙️ Settings** (bottom left of sidebar)
2. Click **"Grading Scale"** tab
3. Select your preferred scale:
   - **Granular** - 13 levels with +/-
   - **Simple** - 5 levels A, B, C, D, F
4. See instant preview of the scale
5. Done! All grades update immediately

### **Option 2: Directly in Code** (Advanced)

Edit `GradingScale.swift` to customize ranges:
```swift
static let simpleScale: [GradeScaleItem] = [
    GradeScaleItem(letter: "A", minScore: 90, maxScore: 100),
    // Modify ranges as desired
]
```

---

## 📍 Where It's Used

The grading scale affects **all** letter grades throughout the app:

### **Dashboard:**
- Subject cards show letter grades
- Charts display letter grades

### **Subjects View:**
- Subject header shows letter grade
- Grade breakdown uses current scale

### **Reports:**
- Grade report shows letter grades
- PDF export includes current grading scale reference
- Scale preview in report

### **All Grade Displays:**
- Every percentage converts to letter grade using selected scale
- Updates in real-time when you change scales

---

## 🔧 Technical Implementation

### **Files Created/Modified:**

1. **`GradingScale.swift`** (NEW)
   - Defines both grading scales
   - `GradingScaleType` enum
   - `GradeScaleItem` struct
   - `GradingScaleDefinition` with both scales
   - Helper methods for scale selection

2. **`DataModels.swift`** (MODIFIED)
   - `Subject.letterGrade` now uses dynamic scale
   - Reads user preference from `UserDefaults`
   - Calculates grade based on selected scale

3. **`ContentView.swift`** (MODIFIED)
   - Added "Grading Scale" tab to Settings
   - `GradingScaleSettingsContent` view
   - `GradingScaleOptionCard` selection UI
   - Scale preview display

4. **`AdditionalViews.swift`** (MODIFIED)
   - Reports dynamically load current scale
   - PDF export uses current scale
   - Grading scale reference shows selected scale

---

## 💾 Persistence

**User's choice is saved in `UserDefaults`:**
- Key: `"gradingScaleType"`
- Values: `"Granular (A+, A, A-, etc.)"` or `"Simple (A, B, C, etc.)"`
- Persists across app launches
- Default: Granular

---

## 🎨 Settings UI

### **Beautiful Scale Selection Cards:**

```
┌─────────────────────────────────────┐
│ 🔢 Granular (A+, A, A-, etc.) ✓    │
│ 13 grade levels with plus/minus     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 📋 Simple (A, B, C, etc.)           │
│ 5 grade levels (A, B, C, D, F)      │
└─────────────────────────────────────┘
```

### **Live Scale Preview:**
Shows the complete grading scale with all ranges

### **Info Notice:**
Explains that changing scale updates all grades immediately

---

## 🚀 User Benefits

### **For Teachers:**
- ✅ Choose complexity level per student needs
- ✅ Switch between scales anytime
- ✅ Instant updates across entire app
- ✅ Professional grade reports either way

### **For Students:**
- ✅ Clear grade expectations
- ✅ Less pressure with simple scale option
- ✅ More precision with granular scale
- ✅ Matches school's grading system

---

## 📖 Examples

### **Example 1: Percentage 95%**
- **Granular Scale:** A (93-97)
- **Simple Scale:** A (90-100)

### **Example 2: Percentage 88%**
- **Granular Scale:** B+ (88-89)
- **Simple Scale:** B (80-89)

### **Example 3: Percentage 78%**
- **Granular Scale:** C+ (78-79)
- **Simple Scale:** C (70-79)

---

## 🔄 How Grades Update

**When you change the scale:**

1. **Instant Update:** All letter grades recalculate
2. **Percentages Stay Same:** Only the letter grade changes
3. **No Data Loss:** Original scores are preserved
4. **Reports Update:** PDF exports use new scale
5. **Dashboard Updates:** Charts and cards refresh

---

## 💡 Customization Options

### **Want Different Ranges?**

Edit `GradingScale.swift`:

```swift
static let simpleScale: [GradeScaleItem] = [
    GradeScaleItem(letter: "A", minScore: 93, maxScore: 100), // Changed from 90
    GradeScaleItem(letter: "B", minScore: 85, maxScore: 93),  // Changed from 80
    // ... etc
]
```

### **Want a Third Scale?**

1. Add to `GradingScaleType` enum:
   ```swift
   case traditional = "Traditional (90, 80, 70, 60)"
   ```

2. Add scale definition:
   ```swift
   static let traditionalScale: [GradeScaleItem] = [
       GradeScaleItem(letter: "A", minScore: 90, maxScore: 100),
       // ... etc
   ]
   ```

3. Update `scale(for:)` method

4. Appears automatically in Settings!

---

## 🎯 Summary

You now have:
- ✅ **Two built-in grading scales** (Granular & Simple)
- ✅ **User-friendly Settings UI** with selection cards
- ✅ **Live preview** of current scale
- ✅ **Instant updates** across entire app
- ✅ **Persistent preference** (saves between launches)
- ✅ **Dynamic reports** with correct scale
- ✅ **Easy customization** for future changes

**To test it:**
1. Open app → Settings → Grading Scale tab
2. Switch between scales
3. Go to Dashboard or Subjects
4. Watch letter grades update!

---

## 📊 Scale Comparison

| Feature | Granular | Simple |
|---------|----------|---------|
| **Grade Levels** | 13 | 5 |
| **Uses +/-** | ✅ Yes | ❌ No |
| **Precision** | High | Low |
| **Complexity** | More | Less |
| **Best For** | College Prep | Elementary |

---

Perfect for homeschool teachers who want flexibility! 🎓
