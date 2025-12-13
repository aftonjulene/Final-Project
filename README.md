#  BEAST MODE - Fitness Tracking App

BY AHMED ARSHAD AND AFTON GOULDING
A comprehensive Flutter-based fitness tracking application that helps users log workouts, track progress, participate in challenges, and connect with a fitness community.

![Flutter](https://img.shields.io/badge/Flutter-3.9.2-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.9.2-blue.svg)
![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)
![License](https://img.shields.io/badge/License-Private-red.svg)

##  Features

### Core Features
- **Workout Logging**: Log your workouts with exercises, sets, reps, and weights
- **Social Feed**: View and interact with workouts from the community
- **Challenges**: Participate in fitness challenges and compete with others
- **Dashboard**: Track your progress with detailed statistics and analytics
- **Photo Journal**: Document your fitness journey with photos
- **User Profiles**: Customize your profile and view workout history
- **Notifications**: Real-time notifications for likes, comments, and challenges
- **Comments & Replies**: Engage with the community through comments and replies

### Key Highlights
- Real-time data synchronization with Firebase
- Image caching for optimal performance
- Push notifications support
- Offline-ready architecture
- Optimized for memory and performance
- Material Design 3 UI

##  Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.9.2 or higher)
  - Check installation: `flutter --version`
  - [Install Flutter](https://docs.flutter.dev/get-started/install)
  
- **Dart SDK** (3.9.2 or higher)
  - Included with Flutter installation

- **Firebase Account**
  - [Create Firebase Project](https://console.firebase.google.com/)

- **Development Tools**
  - **Android Studio** (for Android development)
  - **Xcode** (for iOS development - macOS only)
  - **VS Code** or **Android Studio** (recommended IDEs)

- **Platform-specific Requirements**
  - **Android**: Android SDK, Android Studio
  - **iOS**: Xcode 14+, CocoaPods, macOS
  - **Web**: Chrome (for web development)

##  Installation & Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd beastmode
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

#### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Follow the setup wizard

#### Step 2: Configure Firebase for Android

1. In Firebase Console, click the Android icon
2. Register your app with package name: `com.example.beast_mode`
3. Download `google-services.json`
4. Place it in `android/app/` directory

#### Step 3: Configure Firebase for iOS

1. In Firebase Console, click the iOS icon
2. Register your app with bundle ID: `com.example.beastMode`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

#### Step 4: Configure Firebase for Web

1. In Firebase Console, click the Web icon
2. Register your app
3. Copy the Firebase configuration
4. Update `lib/firebase_options.dart` if needed

#### Step 5: Enable Firebase Services

Enable the following services in Firebase Console:

- **Authentication**
  - Go to Authentication > Sign-in method
  - Enable Email/Password provider

- **Cloud Firestore**
  - Go to Firestore Database
  - Create database in production mode
  - Set up security rules (see `firestore.rules`)

- **Cloud Storage**
  - Go to Storage
  - Get started with default rules
  - Update rules for production (see `storage.rules`)

- **Cloud Messaging** (Optional, for push notifications)
  - Go to Cloud Messaging
  - Follow setup instructions for your platform

#### Step 6: Generate Firebase Options

If you haven't already, generate the Firebase options file:

```bash
flutter pub global activate flutterfire_cli
flutterfire configure
```

This will create/update `lib/firebase_options.dart` with your Firebase configuration.

### 4. Platform-Specific Setup

#### Android Setup

1. **Update `android/app/build.gradle`**:
   ```gradle
   android {
       compileSdkVersion 34
       // ... other config
   }
   ```

2. **Update `android/build.gradle`**:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```

3. **Update `android/app/build.gradle`**:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

#### iOS Setup

1. **Install CocoaPods** (if not already installed):
   ```bash
   sudo gem install cocoapods
   ```

2. **Install Pods**:
   ```bash
   cd ios
   pod install
   cd ..
   ```

3. **Update `ios/Runner/Info.plist`**:
   - Add camera and photo library permissions if needed

#### Web Setup

1. **Update `web/index.html`**:
   - Ensure Firebase SDK is properly included
   - Check that Firebase configuration is correct

### 5. Firestore Security Rules

Update your Firestore security rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Users collection - users can read/write their own profile
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update, delete: if isOwner(userId);
    }

    // Workouts collection - users can read all workouts in feed, write their own
    match /workouts/{workoutId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isAuthenticated(); // Allow likes updates from any authenticated user
      allow delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
      
      // Comments subcollection
      match /comments/{commentId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
        allow update: if isAuthenticated();
        allow delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
        
        // Replies subcollection
        match /replies/{replyId} {
          allow read: if isAuthenticated();
          allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
          allow update, delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
        }
      }
    }

    // Photo Journal collection
    match /photo_journal/{photoId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isOwner(resource.data.userId);
    }

    // Notifications collection
    match /notifications/{notificationId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
    }

    // Challenges collection
    match /challenges/{challengeId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
  }
}
```

### 6. Storage Security Rules

Update your Storage security rules in Firebase Console:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /photo_journal/{userId}/{allPaths=**} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId
        && request.resource.size < 5 * 1024 * 1024 // 5MB limit
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

##  Running the App

### Run on Connected Device/Emulator

1. **Check connected devices**:
   ```bash
   flutter devices
   ```

2. **Run the app**:
   ```bash
   flutter run
   ```

### Run in Specific Mode

- **Debug mode** (default):
  ```bash
  flutter run --debug
  ```

- **Profile mode** (for performance testing):
  ```bash
  flutter run --profile
  ```

- **Release mode** (for production):
  ```bash
  flutter run --release
  ```

### Platform-Specific Commands

- **Android**:
  ```bash
  flutter run -d android
  ```

- **iOS**:
  ```bash
  flutter run -d ios
  ```

- **Web**:
  ```bash
  flutter run -d chrome
  ```

##  Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
│
├── models/                   # Data models
│   ├── challenge.dart
│   ├── challenge_participant.dart
│   ├── exercise.dart
│   ├── journal_entry.dart
│   ├── user_profile.dart
│   └── workout.dart
│
├── screens/                  # UI screens
│   ├── challenges_screen.dart
│   ├── dashboard_screen.dart
│   ├── detailed_stats_screen.dart
│   ├── edit_profile_screen.dart
│   ├── feed_screen.dart
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── main_navigation.dart
│   ├── notifications_screen.dart
│   ├── photo_journal_screen.dart
│   ├── profile_screen.dart
│   ├── settings_screen.dart
│   ├── signup_screen.dart
│   ├── workout_form_screen.dart
│   ├── workout_history_screen.dart
│   └── workout_log_screen.dart
│
├── services/                # Business logic & API calls
│   ├── auth_service.dart
│   ├── challenge_service.dart
│   └── notification_service.dart
│
└── widgets/                 # Reusable widgets
    ├── custom_text_field.dart
    ├── primary_button.dart
    ├── reusable_card.dart
    ├── secondary_button.dart
    └── stat_card.dart
```

##  Dependencies

### Main Dependencies

- **flutter**: SDK framework
- **firebase_core**: ^4.2.1 - Firebase core functionality
- **firebase_auth**: ^6.1.2 - User authentication
- **cloud_firestore**: ^6.1.0 - NoSQL database
- **firebase_storage**: ^13.0.4 - File storage
- **firebase_messaging**: ^16.0.4 - Push notifications
- **cached_network_image**: ^3.3.1 - Image caching
- **image_picker**: ^1.1.2 - Image selection

### Dev Dependencies

- **flutter_test**: Testing framework
- **flutter_lints**: ^5.0.0 - Linting rules

##  Performance Optimizations

This app includes several performance optimizations:

-  **Image Caching**: Uses `cached_network_image` for efficient image loading
-  **Memory Management**: Proper disposal of controllers, listeners, and streams
-  **Query Optimization**: Reduced Firestore queries and nested StreamBuilders
-  **Pagination**: Implemented for feed to reduce initial load time
-  **Lazy Loading**: Optimized data fetching strategies

For detailed information, see [PERFORMANCE_OPTIMIZATION.md](./PERFORMANCE_OPTIMIZATION.md)

##  Testing

### Run Tests

```bash
flutter test
```

### Run Tests with Coverage

```bash
flutter test --coverage
```

### Performance Testing

```bash
flutter run --profile
```

Then use Flutter DevTools to analyze performance.

##  Development

### Code Formatting

```bash
flutter format .
```

### Code Analysis

```bash
flutter analyze
```

### Build for Production

**Android APK**:
```bash
flutter build apk --release
```

**Android App Bundle**:
```bash
flutter build appbundle --release
```

**iOS**:
```bash
flutter build ios --release
```

**Web**:
```bash
flutter build web --release
```

##  Troubleshooting

### Common Issues

#### 1. Firebase Configuration Errors

**Problem**: `FirebaseException: [core/no-app] No Firebase App '[DEFAULT]' has been created`

**Solution**:
- Ensure `firebase_options.dart` is properly generated
- Verify `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in correct locations
- Run `flutterfire configure` again

#### 2. Build Errors on iOS

**Problem**: CocoaPods errors

**Solution**:
```bash
cd ios
pod deintegrate
pod install
cd ..
```

#### 3. Image Picker Not Working

**Problem**: Permission denied errors

**Solution**:
- **Android**: Add permissions in `android/app/src/main/AndroidManifest.xml`
- **iOS**: Add permissions in `ios/Runner/Info.plist`

#### 4. Firestore Permission Denied

**Problem**: Security rules blocking requests

**Solution**:
- Check Firestore security rules in Firebase Console
- Ensure user is authenticated
- Verify rules match the structure in `firestore.rules`

#### 5. App Crashes on Startup

**Problem**: Various initialization errors

**Solution**:
- Clear Flutter build cache: `flutter clean`
- Reinstall dependencies: `flutter pub get`
- Check Firebase configuration
- Verify all required services are enabled in Firebase Console

### Getting Help

- Check [Flutter Documentation](https://docs.flutter.dev/)
- Review [Firebase Documentation](https://firebase.google.com/docs)
- Check existing issues in the repository
- Review [PERFORMANCE_OPTIMIZATION.md](./PERFORMANCE_OPTIMIZATION.md) for performance-related issues

##  Supported Platforms

-  Android (API 21+)
-  iOS (12.0+)
-  Web
-  macOS, Linux, Windows (not fully tested)

## Security Notes

- Never commit `google-services.json` or `GoogleService-Info.plist` to public repositories
- Keep Firestore security rules up to date
- Regularly update dependencies for security patches
- Use environment variables for sensitive configuration

##  License

This project is private and proprietary. All rights reserved.

##  Contributing

This is a private project. For contributions, please contact the project maintainers.

##  Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- All open-source contributors whose packages made this possible

##  Support

For support, please contact the development team or create an issue in the repository.

---

**Made with  using Flutter**
