<<<<<<< HEAD
# Exam Preparation Mobile App

A complete, production-ready, and highly scalable Flutter application built using **Flutter + Supabase** (Auth, DB, and Storage).

## Features

- 🏠 **Dashboard (Home)**: Live countdown timer of the current session, automatically refreshes as time advances without manual reloads. Displays today's study progress hours (completed vs remaining), and upcoming schedules.
- 📚 **Subjects & Chapters Management**: Manually create, search, and edit subjects. View detailed progress bars, note counts, and completion statuses. Supports cascaded deletion of chapters, schedules, and notes.
- 📄 **Notes System**: Upload notes in formats like PDF, images, text, and documents directly to isolated folders in Supabase Storage (`user_id/subject_name/chapter_name/`). Preview, rename, and delete uploaded files.
- 📅 **Day-wise Timetable**: Interactive timetable with date selection strip, step-by-step Wizard Dialog to schedule learning sessions, duplicate sessions for the next day, and check off completed sessions.
- 📈 **Progress Analytics**: Beautiful custom canvas progress charts (sessions and syllabus coverage circles), study streak counters, and study hours metrics.
- 📋 **Professional PDF Reports**: Generate, print, and share detailed progress PDF documents featuring study statistics and syllabus coverage lists.
- 🔔 **Smart Local Notifications**: Automatically schedules push alerts 15 minutes before any study session starts and precisely at the session start.
- ⚙ **Settings Options**: Material 3 dark/light modes, adjustable notification offsets, and portable JSON Backup & Restore.
- 🔍 **Global Search**: Search across subjects, chapters, notes, and timetable slots instantly.

---

## Architecture & Project Structure

The project implements the **MVVM (Model-View-ViewModel)** architecture paired with the **Repository Pattern** to separate database interactions from presentation layers:

```text
lib/
├── models/         # Data structures and JSON mapping (Subject, Chapter, Note, Session, Profile)
├── repositories/   # Abstract data access layers communicating with Supabase
├── services/       # Global singletons (Supabase Client, Notifications, PDF Reports, Backup/Restore)
├── utils/          # Style rules, Material 3 themes, constants
├── viewmodels/     # Business logic layers modifying view states and updating listeners (Provider)
└── views/          # Material 3 UI screens and wizard flow modals
=======
# 📚 Exam Schedule App

An AI-powered exam schedule and study planner designed to help students organize their academic life efficiently. The application enables users to manage subjects, create personalized study schedules, track exam dates, monitor progress, and stay consistent with their preparation.

---

## ✨ Features

* 📅 Smart study timetable
* 📖 Subject management
* 📝 Exam schedule management
* ⏰ Study reminders
* 📊 Progress tracking and analytics
* 🔐 Secure user authentication
* ☁️ Cloud synchronization with Supabase
* 📱 Responsive design for desktop and mobile
* 🤖 AI-assisted scheduling and planning

---

## 🛠️ Tech Stack

### Frontend

* React
* TypeScript
* Tailwind CSS

### Backend

* Supabase
* PostgreSQL
* Supabase Authentication

### Development

* Node.js
* Git
* GitHub

---

## 🚀 Getting Started

### Prerequisites

* Node.js
* npm (or pnpm)
* Git
* Supabase account

### Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/exam-schedule-app.git
```

Navigate into the project:

```bash
cd exam-schedule-app
```

Install dependencies:

```bash
npm install
```

Start the development server:

```bash
npm run dev
>>>>>>> 52315a52b5e8982c3e1050cf65388d834554927b
```

---

<<<<<<< HEAD
## Setup Instructions

### 1. Supabase Backend Integration

1. Go to the [Supabase Dashboard](https://supabase.com) and create a new project.
2. Navigate to the **SQL Editor** tab and execute the SQL commands found in [supabase_schema.sql](file:///C:/Users/geekl/OneDrive/Documents/Exam_Schedule/supabase_schema.sql) to set up all tables, indexes, row security, and study streak auto-increment triggers.
3. Navigate to the **Storage** tab:
   - Create a new bucket named `notes`.
   - Toggle **Allowed MIME Types** to accept your target file extensions: `pdf, doc, docx, ppt, pptx, txt, jpg, png`.
   - Set **Row Level Security (RLS)** policy to allow authenticated users to perform operations inside their own folder:
     - Policy: `All` operations
     - Allowed roles: `authenticated`
     - Condition: `(auth.uid() = (storage.foldername(name))[1])`

### 2. Configure Flutter App Credentials

Open the [lib/utils/constants.dart](file:///C:/Users/geekl/OneDrive/Documents/Exam_Schedule/lib/utils/constants.dart) file and replace the values with your project credentials:

```dart
static const String supabaseUrl = 'https://YOUR_PROJECT_REFERENCE.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANONYMOUS_PUBLIC_KEY';
```

### 3. Native Platform Setup

#### Android (Local Notifications Support)
To support exact scheduling on Android:
- Open `android/app/src/main/AndroidManifest.xml` and add the following permissions inside `<manifest>`:
  ```xml
  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
  <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
  ```
- Specify the default app launcher icon or adjust the initialization name in [lib/services/notification_service.dart](file:///C:/Users/geekl/OneDrive/Documents/Exam_Schedule/lib/services/notification_service.dart).

#### iOS (Local Notifications & Sharing)
- Open `ios/Runner/Info.plist` and add permission description keys for file selection and sharing if required.

---

## How to Run

1. Open a terminal inside the project directory:
   ```bash
   cd Exam_Schedule
   ```
2. Run command to fetch all Dart packages:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```
=======
## ⚙️ Environment Variables

Create a `.env` file and add:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

---

## 📂 Planned Features

* Smart timetable generation
* Daily study planner
* Subject-wise study statistics
* Attendance tracking
* Exam countdown
* Revision planner
* Notifications and reminders
* Dark mode
* Offline support
* Data export and backup
* AI-powered study recommendations

---

## 📈 Project Status

🚧 Currently under active development.

New features and improvements are being added regularly.

---

## 🤝 Contributing

Contributions, suggestions, and feedback are welcome. Feel free to open an issue or submit a pull request.

---

## 📄 License

This project is licensed under the MIT License.

---

## ⭐ Support

If you find this project helpful, consider giving it a ⭐ on GitHub.
>>>>>>> 52315a52b5e8982c3e1050cf65388d834554927b
