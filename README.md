<h1 align="center">
  ✅ Smart Task Manager
</h1>

<p align="center">
  A beautiful, modern, and highly functional task management application built with <strong>Flutter</strong> and <strong>Firebase</strong>. Designed to help users stay organized, track their progress, and never miss a deadline.
</p>

---

## ✨ Features

- **🔐 Secure Authentication:** Seamless user login and signup powered by Firebase Authentication.
- **📊 Interactive Dashboard:** Get real-time analytics on your productivity. View completion rates, pending tasks, and a breakdown of tasks by priority (High, Medium, Low).
- **📝 Comprehensive Task Management:**
  - Create tasks with titles, descriptions, due dates, and priority levels.
  - Mark tasks as complete or delete them with intuitive swipe gestures.
  - Color-coded priority badges and smart handling of overdue tasks.
- **🗓️ Calendar View:** A fully interactive monthly calendar to visualize your schedule and easily find tasks due on specific dates.
- **🎨 Dynamic Theming:** Switch between an elegant Light Mode and a sleek Dark Mode, with preferences saved locally.
- **📱 Responsive UI:** Built with Material 3 design guidelines, featuring a responsive Bottom Navigation Bar for effortless app traversal.

## 🛠️ Tech Stack & Architecture

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** [`provider`](https://pub.dev/packages/provider)
- **Backend as a Service (BaaS):** [Firebase](https://firebase.google.com/)
  - **Firestore:** Real-time NoSQL database for syncing tasks across devices.
  - **Firebase Auth:** Secure user identity management.
- **Key Packages:**
  - [`table_calendar`](https://pub.dev/packages/table_calendar) - For the complex interactive calendar UI.
  - [`intl`](https://pub.dev/packages/intl) - For robust date formatting.
  - [`shared_preferences`](https://pub.dev/packages/shared_preferences) - For persisting local settings like Theme preferences.

## 📸 Screenshots

> **Note:** To make your repository stand out, add some screenshots of the running app here!
>
> | **Dashboard** | **My Tasks** | **Calendar View** | **Profile & Settings** |
> | :---: | :---: | :---: | :---: |
> | *(Add screenshot here)* | *(Add screenshot here)* | *(Add screenshot here)* | *(Add screenshot here)* |

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.7.2`)
- An IDE (VS Code, Android Studio, etc.)
- A Firebase project configured for Android/iOS/Web to obtain `google-services.json` / `GoogleService-Info.plist`.

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/smart_task_manager.git
   cd smart_task_manager
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
    - **Note:** For security reasons, `lib/firebase_options.dart` and `android/app/google-services.json` are excluded from the repository.
    - Use the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) to reconfigure the project to your own Firebase backend.
    - Run `flutterfire configure` inside the project directory to generate your own configuration files.

4. **Run the app**
   ```bash
   flutter run
   ```

## 📂 Project Structure

A quick overview of the application's clean architecture:

```text
lib/
├── models/         # Data representations (e.g., Task model, Priority enums)
├── providers/      # App-wide state (e.g., ThemeProvider)
├── screens/        # UI Views (Dashboard, Home, Calendar, Profile, Login/Signup)
├── services/       # Core business logic communicating with Firebase (AuthService, TaskService)
├── widgets/        # Reusable UI components
├── main.dart       # App entry point, Provider injection, and Theme configuration
└── splash_screen/  # Initial loading/branding screen
```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](../../issues).

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
