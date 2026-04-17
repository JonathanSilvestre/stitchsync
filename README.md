# StitchSync

Cross-platform mobile app for collaborative pet care management.

StitchSync helps families organize routines, events, and responsibilities for their pets in one place, with real-time sync and local reminders.

## Table of contents

- [Overview](#overview)
- [Core features](#core-features)
- [Tech stack](#tech-stack)
- [Architecture](#architecture)
- [Project structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation and run](#installation-and-run)
- [Firebase setup](#firebase-setup)
- [Notifications](#notifications)
- [Key user flows](#key-user-flows)
- [Quality checklist](#quality-checklist)
- [Suggested roadmap](#suggested-roadmap)

## Overview

StitchSync is designed to solve a common problem: keeping daily pet care synchronized when multiple people are involved.

The app centralizes:

- User account management.
- Family and member management.
- Shared pet management.
- Event scheduling (feeding, walks, medication, vet visits, etc.).
- Category-based local reminders.

## Core features

### 1. Authentication and profile

- Sign up and login with Firebase Authentication.
- Editable user profile.
- Profile avatar picker (8 options).
- Language preference (Spanish / English).

### 2. Family collaboration

- Create and join families using invitation codes.
- Role management (owner, admin, member).
- Active member visibility.

### 3. Pet management

- Create, edit, and manage pets.
- Pet avatar selection.
- Active pet context for event synchronization.

### 4. Events and reminders

- Create categorized events.
- Recurrence support.
- Local reminders scheduled 5 minutes before each event.
- Automatic reschedule/cancel when events are edited, completed, or deleted.

### 5. Notification preferences

- Global push enable/disable.
- Category-level control:
  - Feeding & Water
  - Walks & Exercise
  - Medication & Vet
  - Family Updates
- Configurable Quiet Hours.

## Tech stack

- Flutter (Dart)
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- flutter_local_notifications
- timezone + flutter_timezone

## Architecture

The app uses a lightweight layered structure:

- screens: UI and navigation flows.
- services: business logic and Firebase access.
- utils: catalogs and UI helper utilities (for example, avatars).

Patterns used:

- Stateful Widgets for screen state.
- Service classes to encapsulate domain logic.
- Firestore as the shared source of truth.

## Project structure

```text
lib/
  main.dart
  firebase_options.dart
  screens/
    account_settings_screen.dart
    profile_screen.dart
    family_screen.dart
    manage_family_screen.dart
    manage_pets_screen.dart
    notifications_screen.dart
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

## Prerequisites

- Flutter SDK installed.
- Android Studio or VS Code with Flutter/Dart extensions.
- Firebase project.
- Physical device or Android/iOS emulator.

## Installation and run

1. Clone the repository.
2. Install dependencies:

```bash
flutter pub get
```

3. Verify Firebase configuration.
4. Run the app:

```bash
flutter run
```

5. Run static analysis:

```bash
flutter analyze
```

## Firebase setup

This project requires Firebase for authentication and database.

General steps:

1. Create a Firebase project in Firebase Console.
2. Register Android/iOS apps.
3. Add platform config files.
4. Run FlutterFire Configure to generate Firebase options.
5. Validate Firestore rules for your environment (development/production).

Note:
The repository already contains related files such as firebase.json, firestore.rules, and firebase_options.dart.

## Notifications

StitchSync uses local notifications for event reminders.

Key behavior:

- Scheduled 5 minutes before the event.
- Filtered by category preferences.
- Respect Quiet Hours.
- Upcoming reminders are synced on app startup.

Android details:

- Exact alarms support.
- Re-scheduling support after device reboot.
- Runtime notification permissions based on Android version.

## Key user flows

- Sign up/Login -> Profile -> Create or join family -> Add pets -> Schedule events -> Receive reminders.
- Account settings -> Update username/password/language/avatar.
- Family management -> Manage members, roles, and shared data.

## Quality checklist

Recommended before opening a Pull Request:

- Run `flutter analyze`.
- Test full authentication flow.
- Test profile saving (username, avatar, language).
- Test pet and event CRUD.
- Test local notifications on a physical device.

## Suggested roadmap

- Full UI internationalization.
- Unit tests for service layer.
- Integration tests for critical flows.
- Advanced multi-device synchronization.
- Family activity dashboard.

---

If you want to contribute, create a `feature/*` branch, document your changes, and open a Pull Request with functional details and testing evidence.
