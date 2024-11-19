# Founditure Android Application

## Overview

Founditure is a cutting-edge mobile application that revolutionizes furniture shopping through AI-powered recognition, location-based services, and social features. The application targets Android 10+ devices, leveraging modern Android development practices and Jetpack Compose for a native Material Design 3 experience.

## Prerequisites

Before starting development, ensure you have the following installed:

- Android Studio Electric Eel or newer
- JDK 17 or higher
- Android SDK Platform 34 (Android 14)
- Gradle 8.0+
- Git

### System Requirements

- 8GB RAM minimum (16GB recommended)
- 10GB free disk space
- Windows 10/11, macOS 10.15+, or Linux with GUI
- Intel i5/AMD Ryzen 5 or better processor

## Getting Started

1. Clone the repository:
```bash
git clone https://github.com/founditure/android-app.git
cd android-app
```

2. Open Android Studio and import the project

3. Configure local environment:
   - Create `local.properties` in the project root
   - Add your Android SDK path:
     ```properties
     sdk.dir=/path/to/your/Android/Sdk
     ```

4. Firebase Setup:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Download `google-services.json`
   - Place it in the `app/` directory

5. Build and run:
   ```bash
   ./gradlew assembleDebug
   ```

## Architecture

The application follows Clean Architecture principles with MVVM pattern:

### Layer Structure

```
app/
├── data/           # Data layer (repositories, data sources)
├── domain/         # Business logic and models
├── presentation/   # UI layer (composables, view models)
└── di/             # Dependency injection modules
```

### Key Components

- **UI Layer**: Jetpack Compose (v1.5.4)
- **Dependency Injection**: Hilt (v2.48)
- **Local Storage**: Room Database (v2.6.0)
- **Network**: Retrofit2 + OkHttp3
- **Authentication**: Firebase Auth
- **Messaging**: Firebase Cloud Messaging
- **Location**: Google Play Services Location

## Features

### 1. Authentication
- Firebase Authentication integration
- Email/password and Google Sign-In
- Secure token management
- Offline authentication support

### 2. Furniture Recognition
- AI-powered furniture detection
- Camera API integration
- Real-time image processing
- Furniture categorization and matching

### 3. Location Services
- Nearby furniture store discovery
- Real-time location tracking
- Geofencing for store notifications
- Distance calculation and routing

### 4. Messaging
- Push notifications via FCM
- In-app messaging
- Chat support
- Notification preferences

### 5. Offline Support
- Room Database integration
- Data synchronization
- Offline-first architecture
- Background sync workers

## Testing

### Unit Tests
```bash
./gradlew test
```

### Instrumentation Tests
```bash
./gradlew connectedAndroidTest
```

### UI Tests
```bash
./gradlew connectedCheck
```

## Contributing

### Code Style

- Follow [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html)
- Use meaningful variable and function names
- Document public APIs
- Maximum line length: 120 characters

### Pull Request Process

1. Create a feature branch from `develop`
2. Implement changes with tests
3. Update documentation
4. Submit PR with description
5. Pass CI checks
6. Get code review approval

### Commit Guidelines

Follow conventional commits:
```
feat: add user profile screen
fix: resolve camera permission crash
docs: update API documentation
test: add authentication tests
```

## Build & Deploy

### Debug Build
```bash
./gradlew assembleDebug
```

### Release Build
1. Configure signing:
   - Create `keystore.properties`:
     ```properties
     storeFile=founditure.keystore
     storePassword=<password>
     keyAlias=<alias>
     keyPassword=<password>
     ```

2. Build release APK:
   ```bash
   ./gradlew assembleRelease
   ```

### Play Store Deployment

1. Generate signed bundle:
   ```bash
   ./gradlew bundleRelease
   ```

2. Upload to Play Console:
   - Access [Play Console](https://play.google.com/console)
   - Navigate to Release Management
   - Create new release
   - Upload bundle
   - Submit for review

## Version Information

- Application ID: com.founditure
- Version Name: 1.0.0
- Minimum SDK: 29 (Android 10)
- Target SDK: 34 (Android 14)
- Kotlin Version: 1.9.0
- Compose Version: 1.5.4

## Support

For technical support or questions:
- Create an issue in the repository
- Contact the development team
- Check the [Wiki](https://github.com/founditure/android-app/wiki)