# Founditure iOS Application

## Project Overview
Founditure is a mobile application designed to revolutionize furniture shopping through augmented reality and advanced visualization features. This iOS version is built using Swift and SwiftUI, targeting iOS 14.0 and above.

## Requirements

### Tools
- Xcode 14.0+ (Primary IDE)
- CocoaPods 1.12+ (Dependency Manager)
- Swift 5.9+ (Programming Language)
- SwiftLint 0.52.0 (Code Quality Tool)

### System Requirements
- macOS Ventura or later
- iOS 14.0+ deployment target
- Minimum 16GB RAM recommended
- Apple Developer Account for deployment

## Getting Started

### 1. Clone Repository
```bash
git clone [repository-url]
cd src/ios
```

### 2. Install Dependencies
```bash
sudo gem install cocoapods
pod install
```

### 3. Configure Credentials
1. Firebase Setup
   - Add `GoogleService-Info.plist` to the project
   - Configure Firebase credentials in Xcode project settings

2. Google Maps Configuration
   - Add Google Maps API key in `Info.plist`:
   ```xml
   <key>GMSApiKey</key>
   <string>YOUR_API_KEY</string>
   ```

3. SwiftLint Setup
   - SwiftLint configuration is already provided in `.swiftlint.yml`
   - No additional setup required as it's included in Podfile

## Project Structure

### Key Directories
```
src/ios/
├── Founditure/           # Main application source
├── FounditureTests/      # Unit tests
├── FounditureUITests/    # UI tests
├── Pods/                 # Dependencies
├── Podfile              # CocoaPods configuration
├── Podfile.lock         # Dependency lock file
└── .swiftlint.yml       # SwiftLint configuration
```

## Dependencies
The project uses the following key dependencies (managed via CocoaPods):

- Firebase Suite (v10.0.0)
  - Firebase/Auth
  - Firebase/Messaging
  - Firebase/Analytics
- Alamofire (v5.8.0) - Networking
- SDWebImage (v5.18.0) - Image handling
- GoogleMLKit/ObjectDetection (v4.0.0) - AR features
- Socket.IO-Client-Swift (v16.1.0) - Real-time communication
- GoogleMaps (v8.0.0) - Location services
- Sentry (v8.0.0) - Error tracking
- KeychainAccess (v4.2.2) - Secure storage

## Development Guidelines

### Code Style
We follow strict coding standards enforced by SwiftLint. Key rules include:
- Maximum line length: 120 characters (warning), 150 characters (error)
- File length: 400 lines (warning), 500 lines (error)
- Function body length: 50 lines (warning), 80 lines (error)
- Cyclomatic complexity: 10 (warning), 15 (error)

Refer to `.swiftlint.yml` for complete style guidelines.

## Testing

### Unit Tests
```bash
xcodebuild test -workspace Founditure.xcworkspace -scheme Founditure -destination 'platform=iOS Simulator,name=iPhone 14,OS=latest'
```

### UI Tests
```bash
xcodebuild test -workspace Founditure.xcworkspace -scheme Founditure -destination 'platform=iOS Simulator,name=iPhone 14,OS=latest' -testPlan UITests
```

## Deployment

### Development Build
1. Select appropriate provisioning profile
2. Set build configuration to Debug
3. Build and run on device/simulator

### Release Build
1. Update version and build numbers
2. Select Release configuration
3. Archive project
4. Upload to App Store Connect

## Troubleshooting

### Common Issues

1. Pod Install Fails
```bash
pod repo update
pod install --repo-update
```

2. Build Errors
- Clean build folder (Cmd + Shift + K)
- Clean build cache (Cmd + Shift + Alt + K)
- Delete derived data
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

3. Simulator Issues
```bash
xcrun simctl erase all
```

4. SwiftLint Errors
- Ensure SwiftLint is installed: `brew install swiftlint`
- Check `.swiftlint.yml` configuration
- Run manually: `swiftlint lint --config .swiftlint.yml`

### Support
For additional support:
- Check project documentation
- Contact technical lead
- Submit issue in project repository

---
**Note**: This documentation addresses requirements from:
- iOS Development Environment (4.1 PROGRAMMING LANGUAGES)
- Mobile Development Tools (4.2 FRAMEWORKS & LIBRARIES)
- Development Environment Setup (A.1)