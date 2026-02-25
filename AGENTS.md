# Agent Guidelines for DarkFeed

This document provides coding standards and development workflows for AI agents working on this Flutter project.

## Project Overview

- **Language**: Dart 3.11.0+
- **Framework**: Flutter (stable channel)
- **Type**: Mobile/Desktop/Web application
- **Platforms**: Android, iOS, Linux, macOS, Web, Windows

## Build, Lint, and Test Commands

### Essential Commands

```bash
# Install dependencies
flutter pub get

# Run the application
flutter run                    # Debug mode
flutter run -d <device-id>     # Specific device

# Analysis and formatting
flutter analyze                                            # Check for errors
dart fix --apply                                           # Auto-fix issues
dart format lib/ test/                                     # Format code
dart format --output=none --set-exit-if-changed lib/ test/ # Check format only
```

### Testing

```bash
flutter test                              # Run all tests
flutter test test/widget_test.dart        # Run a single test file
flutter test --name="Counter increments"  # Run specific test by name
flutter test --coverage                   # Run with coverage
flutter test --watch                      # Watch mode (re-run on changes)
```

### Build Commands

```bash
flutter build apk         # Android APK
flutter build appbundle   # Android App Bundle
flutter build ios         # iOS
flutter build web         # Web
flutter build linux       # Linux
flutter build macos       # macOS
flutter build windows     # Windows
```

## Code Style Guidelines

### Imports

Order: Dart SDK → Flutter → External packages → Internal packages. Separate groups with blank lines.

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cupertino_icons/cupertino_icons.dart';

import 'package:darkfeed/models/user.dart';
```

### Formatting and Naming

- **Line length**: 80 characters, **Indentation**: 2 spaces
- **Trailing commas**: Always use for multi-line calls/collections
- **Classes/Enums**: `UpperCamelCase` (e.g., `MyHomePage`)
- **Files/Directories**: `lowercase_with_underscores` (e.g., `user_profile.dart`)
- **Variables/Parameters**: `lowerCamelCase` (e.g., `userName`)
- **Constants**: `lowerCamelCase` (e.g., `defaultTimeout`)
- **Private members**: Prefix with `_` (e.g., `_counter`)
- Run `dart format` before committing

### Types and Widgets

- Always specify types for public APIs, fields, return values
- Prefer `final` over `var`; use `const` for immutable widgets
- Use `super.key` parameter for all widget constructors
- Extract widgets to classes, not methods (better performance)

```dart
// Good types
final int counter = 0;
const String appName = 'DarkFeed';

// Good widget
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
  
  @override
  Widget build(BuildContext context) => const Text('Hello');
}
```

### Error Handling and Documentation

- Use exceptions, not error codes; catch specific exceptions
- Provide meaningful error messages; use `assert` for dev checks
- Use `///` for public API docs (dartdoc), `//` for implementation comments
- Document all public classes, methods, properties

## Testing Guidelines

- **Location**: `test/` directory (mirrors `lib/` structure)
- **Naming**: Test files must end with `_test.dart`
- **Widget tests**: Use `testWidgets` with `WidgetTester`
- **Unit tests**: Use `test` for pure Dart code
- **Structure**: Follow Arrange-Act-Assert pattern

```dart
testWidgets('Counter increments when button is tapped', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  expect(find.text('1'), findsOneWidget);
});
```

## File Organization

```
lib/
├── main.dart       # Application entry point
├── models/         # Data models
├── screens/        # Screen/page widgets
├── widgets/        # Reusable widgets
├── services/       # Business logic and API services
├── utils/          # Utility functions
└── constants/      # App-wide constants
```

## Best Practices

1. **State Management**: Use `setState` for simple state; consider Provider/Riverpod/Bloc for complex apps
2. **Null Safety**: Handle nulls with `?`, `!`, and `??` operators
3. **Performance**: Use `const` constructors, `ListView.builder` for long lists
4. **Linting**: Uses `package:flutter_lints` - fix all warnings before committing
5. **Assets**: Define all assets in `pubspec.yaml` before use

## Git Workflow

- Never commit generated files (`build/`, `.dart_tool/`)
- Run `flutter analyze` and `flutter test` before committing
- Format code with `dart format` before committing
