# Shohagh Ticket Validator

This is an internal Flutter application for Shohagh Paribahan staff to validate tickets using QR code scanning. It integrates with the Freeway API and Firebase for crash tracking and data management.

## Key Features
- QR Code Scanning & PNR Validation
- OTP based Staff Authentication
- Offline PNR caching for faster verification
- Crashlytics & Analytics integration
- Professional UI/UX with smooth animations

## Build & Run
### Android
1. Get dependencies: `flutter pub get`
2. Create `android/key.properties` with keystore details.
3. Run: `flutter run --release`
4. Build APK: `flutter build apk --release`

### iOS
1. Requirement: macOS with Xcode installed.
2. Setup Firebase: Add `GoogleService-Info.plist` to `ios/Runner/` via Xcode.
3. Install pods: `cd ios && pod install`
4. Run: `flutter run --release`
5. Build: `flutter build ios --release`

## Documentation
For detailed information on the application architecture and verification flow, see:
- [Verification Architecture](VERIFICATION_ARCHITECTURE.md)

## Project Structure
- `lib/core`: API services, providers, and shared models.
- `lib/features`: Feature-based UI modules (auth, verification, trip management).
- `assets/`: UI assets and logos.


