# ProTrack

A professional tracking application built with Flutter that helps users monitor their career growth, set goals, and track achievements.

## Features

- **Progress Tracking**: Monitor your professional growth and achievements
- **Goal Setting**: Define and track your career objectives
- **Profile Management**: Keep your professional information organized
- **Modern UI**: Clean and intuitive user interface
- **Responsive Design**: Works on both mobile and tablet devices

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK (latest version)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/protrack.git
```

2. Navigate to the project directory:
```bash
cd protrack
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   ├── goals_screen.dart
│   └── progress_screen.dart
├── services/
│   └── auth_service.dart
├── models/
├── widgets/
├── utils/
├── constants/
└── main.dart
```

## Dependencies

- `provider`: State management
- `shared_preferences`: Local storage
- `google_fonts`: Custom fonts
- `flutter_svg`: SVG support
- `intl`: Internationalization
- `flutter_local_notifications`: Local notifications
- `path_provider`: File system access
- `sqflite`: Local database

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 