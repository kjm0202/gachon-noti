# Technology Stack

## Backend (Node.js RSS Crawler)
- **Runtime**: Node.js with ES modules
- **Dependencies**:
  - `node-fetch`: HTTP requests for RSS feeds
  - `fast-xml-parser`: XML/RSS parsing
  - `@supabase/supabase-js`: Database client
  - `firebase-admin`: Push notifications

## Frontend (Flutter App)
- **Framework**: Flutter 3.5.4+
- **State Management**: GetX (Get 4.7.2)
- **Key Dependencies**:
  - `firebase_core`, `firebase_messaging`, `firebase_crashlytics`: Firebase integration
  - `supabase_flutter`: Database client
  - `google_sign_in`: Authentication
  - `google_mobile_ads`: Monetization
  - `flutter_local_notifications`: Local notifications
  - `url_launcher`: External links
  - `package_info_plus`: App version info
  - `qonversion_flutter`: Subscription management

## Database & Services
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Google Sign-In
- **Push Notifications**: Firebase Cloud Messaging
- **Analytics**: Firebase Crashlytics
- **Ads**: Google Mobile Ads + AdFit

## Development Tools
- **Flutter Version Manager**: FVM (`.fvmrc` present)
- **IDE**: Android Studio/IntelliJ (`.idea` folder)
- **Linting**: `flutter_lints: ^5.0.0`

## Common Commands

### Backend
```bash
# Start RSS crawler
npm start

# Install dependencies
npm install
```

### Frontend
```bash
# Get dependencies
flutter pub get

# Run app (development)
flutter run

# Build for production
flutter build apk --release
flutter build web --release

# Generate launcher icons
flutter pub run flutter_launcher_icons

# Run tests
flutter test
```

## Environment Variables (Backend)
- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_SERVICE_KEY`: Service role key
- `FIREBASE_PROJECT_ID`: Firebase project ID
- `FIREBASE_CLIENT_EMAIL`: Service account email
- `FIREBASE_PRIVATE_KEY`: Service account private key