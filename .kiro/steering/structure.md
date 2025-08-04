# Project Structure

## Root Level
```
├── front/                 # Flutter mobile app
├── index.js              # Node.js RSS crawler
├── package.json          # Backend dependencies
└── README.md             # Project documentation
```

## Backend Structure
- **index.js**: Main RSS crawler script
  - Fetches RSS feeds from Gachon University boards
  - Parses XML and stores new posts in Supabase
  - Sends push notifications via Firebase

## Frontend Structure (Flutter App)

### Core Architecture
The Flutter app follows **GetX MVC pattern** with modular organization:

```
front/lib/
├── main.dart                    # App entry point
├── theme.dart                   # App theming
├── firebase_options.dart        # Firebase configuration
└── app/
    ├── bindings/               # Dependency injection
    ├── data/                   # Data layer
    │   ├── models/            # Data models
    │   └── services/          # API services
    ├── modules/               # Feature modules (MVC)
    │   ├── home/              # Main navigation
    │   ├── login/             # Authentication
    │   ├── posts/             # Post listings
    │   ├── settings/          # App settings
    │   └── subscription/      # Subscription management
    ├── routes/                # Navigation routing
    └── utils/                 # Shared utilities
```

### Module Structure (GetX Pattern)
Each module follows the same structure:
```
modules/[feature]/
├── controllers/           # Business logic (GetX controllers)
├── views/                # UI components
└── bindings/             # Dependency injection (if needed)
```

### Key Directories
- **utils/**: Shared utilities including ad widgets, platform utils, notification handlers
- **routes/**: App navigation using GetX routing
- **bindings/**: Dependency injection setup
- **data/models/**: Data transfer objects and models
- **data/services/**: API communication services

## Configuration Files
- **front/pubspec.yaml**: Flutter dependencies and app metadata
- **front/firebase.json**: Firebase hosting configuration
- **front/netlify.toml**: Netlify deployment settings
- **front/.fvmrc**: Flutter version management

## Platform-Specific
- **front/android/**: Android-specific configurations
- **front/ios/**: iOS-specific configurations  
- **front/web/**: Web/PWA configurations
- **front/assets/**: App icons and static assets

## Development Files
- **front/.dart_tool/**: Dart build artifacts
- **front/build/**: Compiled app outputs
- **front/test/**: Unit and widget tests