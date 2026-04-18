# StitchSync

Cross-platform Flutter app for collaborative pet care management.

StitchSync helps families coordinate routines, health tasks, and reminders for shared pets in one place, with Firebase-backed sync and local notifications.

## Contents

- [Why StitchSync](#why-stitchsync)
- [Feature highlights](#feature-highlights)
- [Technology stack](#technology-stack)
- [Architecture and design](#architecture-and-design)
- [Project structure](#project-structure)
- [Getting started](#getting-started)
- [Firebase configuration](#firebase-configuration)
- [Notifications behavior](#notifications-behavior)
- [Main user flows](#main-user-flows)
- [Quality and validation](#quality-and-validation)
- [Roadmap](#roadmap)
- [Contributing](#contributing)

## Why StitchSync

When multiple people care for the same pet, routines can become fragmented.

StitchSync solves this by centralizing:

- Shared pet ownership and family collaboration.
- Event planning with recurrence support.
- Category-based reminders.
- User profile and language preferences.
- Real-time updates across members.

## Feature highlights

### Authentication and profile

- Firebase Authentication sign up and login.
- Editable profile data.
- Avatar selection for users.
- App language selector (Spanish and English).

### Family collaboration

- Create and join families with invitation codes.
- Role support (owner, admin, member).
- Visibility of active members.

### Pet lifecycle management

- Create, update, and manage pets.
- Pet avatar selection.
- Shared context for events per active pet.
- Breed autocomplete while typing in pet forms.

### Events and reminders

- Categorized event creation.
- Recurring events.
- Automatic birthday special event generation.
- Local reminders with category preference filtering.
- Automatic reminder reschedule on event updates.

### Notification preferences

- Global notifications on or off.
- Category-level configuration:
  - Feeding and Water
  - Walks and Exercise
  - Medication and Vet
  - Family Updates
- Quiet hours configuration.
- Preference persistence and sync behavior.

## Technology stack

- Flutter and Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- flutter_local_notifications
- timezone and flutter_timezone

## Architecture and design

StitchSync follows a lightweight layered structure:

- screens: presentation layer and navigation flows.
- services: domain logic and Firebase access.
- utils: shared UI catalogs and helpers.
- l10n: in-app localization resources.

Key design decisions:

- Stateful widgets for local screen state.
- Service-driven domain operations.
- Firestore as shared source of truth.
- Local persistence for resilient notification preferences.

## Project structure

```text
lib/
  main.dart
  firebase_options.dart
  l10n/
    app_i18n.dart
  screens/
    home_screen.dart
    calendar_screen.dart
    notifications_screen.dart
    add_new_pet_screen.dart
    ...
  services/
    auth_service.dart
    family_service.dart
    pet_service.dart
    event_service.dart
    notification_service.dart
  utils/
    pet_avatar_catalog.dart
    user_avatar_catalog.dart
```

## Getting started

### Prerequisites

- Flutter SDK installed and available in PATH.
- Android Studio or VS Code with Flutter and Dart extensions.
- A Firebase project.
- Physical device or emulator.

### Installation

1. Clone the repository.
2. Install dependencies:

```bash
flutter pub get
```

3. Confirm Firebase files are configured for your environment.
4. Run the app:

```bash
flutter run
```

5. Validate static analysis:

```bash
flutter analyze
```

## Firebase configuration

This project requires Firebase for authentication and Firestore data.

Recommended setup flow:

1. Create a Firebase project in Firebase Console.
2. Register Android and iOS apps.
3. Add platform configuration files.
4. Run FlutterFire Configure to generate Firebase options.
5. Review Firestore security rules for your stage (development or production).

Repository includes related configuration files such as:

- firebase.json
- firestore.rules
- lib/firebase_options.dart

## Notifications behavior

StitchSync schedules local reminders for upcoming events.

Current behavior:

- Event reminders are planned before scheduled event time.
- Filtering is applied based on saved category preferences.
- Quiet hours are respected by notification logic.
- Reminder plans are refreshed when events are edited, completed, or removed.
- Birthday special reminders are managed with dedicated handling.

Android notes:

- Supports exact alarms.
- Supports reminder restoration logic.
- Handles runtime notification permission scenarios by OS version.

## Main user flows

- Sign up or login -> complete profile -> create or join family -> add pets -> create events -> receive reminders.
- Account settings -> update username, password, language, and avatar.
- Family management -> invite members, manage roles, maintain shared data.

## Quality and validation

Recommended before opening a pull request:

- Run flutter analyze and resolve warnings.
- Verify complete authentication flow.
- Validate profile updates and persistence.
- Validate pet and event CRUD across screens.
- Validate local notifications on a physical device.
- Re-check localization in Spanish and English.

## Roadmap

- Expand automated tests for service and UI flows.
- Improve multi-device sync conflict handling.
- Add richer family activity insights.
- Extend accessibility and UX consistency.
- Strengthen CI checks for lint, analyze, and tests.

## Contributing

Contributions are welcome.

1. Create a branch using feature or fix naming.
2. Keep commits focused and descriptive.
3. Document functional changes in the pull request.
4. Include validation evidence (analyze, manual flow checks, and screenshots when relevant).

For significant changes, open an issue first to align on scope and approach.
