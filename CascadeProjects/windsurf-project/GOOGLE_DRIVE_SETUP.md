# 🔵 Google Drive Integration Setup

## 📋 Prerequisites

To add Google Drive OAuth authentication, you need:

1. **Google Cloud Console Account** (free)
2. **OAuth 2.0 Client ID** (we'll create this)
3. **Google Sign-In SDK** (we'll add to Xcode)

---

## 🚀 Step-by-Step Setup

### **Part 1: Google Cloud Console Setup (5-10 minutes)**

#### 1. Create Google Cloud Project

1. Go to: https://console.cloud.google.com/
2. Click **"Create Project"** or select existing project
3. Name it: **"Gradebook Plus"**
4. Click **Create**

#### 2. Enable Google Drive API

1. In your project, go to **APIs & Services → Library**
2. Search for **"Google Drive API"**
3. Click **Enable**

#### 3. Create OAuth Consent Screen

1. Go to **APIs & Services → OAuth consent screen**
2. Choose **External** (unless you have Google Workspace)
3. Fill in required fields:
   - **App name:** Gradebook Plus
   - **User support email:** Your email
   - **Developer contact:** Your email
4. Click **Save and Continue**
5. **Scopes:** Click "Add or Remove Scopes"
   - Add: `https://www.googleapis.com/auth/drive.file`
   - This lets the app create files in Drive (read/write only files it creates)
6. Click **Save and Continue**
7. **Test users:** Add your Google email
8. Click **Save and Continue**

#### 4. Create OAuth 2.0 Client ID

1. Go to **APIs & Services → Credentials**
2. Click **+ Create Credentials → OAuth client ID**
3. Select **macOS** as application type
4. Name: **"Gradebook Plus macOS"**
5. Bundle ID: **`com.gradebook.GradebookApp`**
   - (Must match your Xcode project bundle ID)
6. Click **Create**
7. **SAVE THESE VALUES:**
   - Client ID: `1234567890-abcdefghijk.apps.googleusercontent.com`
   - Copy this - you'll need it!

---

### **Part 2: Add Google Sign-In to Xcode (10 minutes)**

#### 1. Add Swift Package Dependency

1. Open `GradebookApp.xcodeproj` in Xcode
2. Select project in navigator
3. Select **GradebookApp** target
4. Go to **Package Dependencies** tab
5. Click **+** button
6. Enter: `https://github.com/google/GoogleSignIn-iOS`
7. Click **Add Package**
8. Select **GoogleSignIn** and **GoogleSignInSwift**
9. Click **Add Package**

#### 2. Configure URL Scheme

1. Select **GradebookApp** target
2. Go to **Info** tab
3. Expand **URL Types**
4. Click **+** to add URL Type
5. Set:
   - **Identifier:** `com.googleusercontent.apps.YOUR_CLIENT_ID`
   - **URL Schemes:** `com.googleusercontent.apps.YOUR_CLIENT_ID`
   - Replace `YOUR_CLIENT_ID` with the REVERSED client ID
   - Example: If client ID is `123-abc.apps.googleusercontent.com`
   - URL Scheme is: `com.googleusercontent.apps.123-abc`

#### 3. Add GoogleService-Info.plist (Optional but Recommended)

Create file: `GradebookApp/GoogleService-Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CLIENT_ID</key>
    <string>YOUR_CLIENT_ID_HERE.apps.googleusercontent.com</string>
    <key>REVERSED_CLIENT_ID</key>
    <string>com.googleusercontent.apps.YOUR_CLIENT_ID_HERE</string>
</dict>
</plist>
```

Replace `YOUR_CLIENT_ID_HERE` with your actual client ID.

---

### **Part 3: I'll Implement the Code**

Once you complete the above setup and provide me with your **Client ID**, I'll:

1. ✅ Add Google Sign-In integration
2. ✅ Implement OAuth flow with pop-up
3. ✅ Add Drive API upload functionality
4. ✅ Handle authentication state
5. ✅ Upload backup files to Google Drive

---

## 🔐 What User Will See

1. **Settings → Select "Manual Export"**
2. Click **"Connect to Google Drive"**
3. **Google Sign-In window pops up** 🎉
   - User signs in with Google account
   - Approves Drive file access
4. Success! **"Google Drive Connected"**
5. Click **"Backup to Google Drive"**
6. File uploads to their Google Drive
7. Shows: **"Last backup: [timestamp]"**

---

## 📱 User Experience Flow

```
┌─────────────────────────────────────┐
│ Click "Connect to Google Drive"     │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│ 🪟 Google Sign-In Window Opens      │
│                                     │
│  Sign in with Google                │
│  [email input]                      │
│  [password input]                   │
│  [Sign In button]                   │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│ ✅ "Google Drive Connected"         │
│                                     │
│ [Backup to Google Drive button]     │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│ 📤 Uploading to Google Drive...     │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│ ✅ Backup Complete!                 │
│ Last backup: Nov 7, 2025 22:30     │
└─────────────────────────────────────┘
```

---

## ⚡ Quick Start (TL;DR)

1. **Google Cloud Console:**
   - Create project
   - Enable Drive API
   - Create OAuth Client ID (macOS)
   - Copy Client ID

2. **Xcode:**
   - Add GoogleSignIn package
   - Add URL scheme (reversed client ID)
   - Build project

3. **Tell me:**
   - "Here's my Client ID: `xxxx.apps.googleusercontent.com`"

4. **I'll implement:**
   - OAuth flow
   - Drive upload
   - Complete integration

---

## 🎯 Alternative: Start Without OAuth (Testing)

If you want to test the UI flow first without OAuth setup:

1. I can create a **mock authentication** that simulates the flow
2. Shows the same UI/UX
3. Saves files locally with proper Drive-like structure
4. Then swap in real OAuth when ready

**Want me to:**
- **A)** Create mock Google auth flow for testing?
- **B)** Wait for you to set up Google Cloud Console and provide Client ID?

---

## 💡 Benefits of Real Google Drive

✅ **User benefits:**
- Sign in with existing Google account
- Files appear in their Google Drive
- Can access from any device
- Automatic cloud backup
- Familiar Google interface

✅ **Your benefits:**
- No server infrastructure needed
- Google handles auth security
- Free (within Drive API limits)
- Professional user experience

---

## 📝 Notes

- **Free Tier Limits:** 1 billion requests/day (more than enough!)
- **User Storage:** Uses their Google Drive quota
- **Security:** OAuth tokens stored securely in Keychain
- **Privacy:** App only accesses files it creates

Let me know if you want to proceed with real OAuth or start with a mock version for testing!
