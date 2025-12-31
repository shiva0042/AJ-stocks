# AJ Stocks Delivery Tracker

A generic mobile app for tracking stock deliveries, designed for owners and delivery personnel.

## Features

- **Task Management**: Create tasks with Shop Name, Stock Name, Quantity, and Notes.
- **Dashboard**: View Active and Delivered tasks.
- **Urgent Tasks**: Tasks not delivered within 24 hours are automatically marked as Urgent and shown at the top.
- **Statuses**:
  - **Pending**: Default status.
  - **Partial**: Log partial deliveries (quantity delivered/remaining).
  - **Delivered**: Move to history.
  - **Urgent**: High priority (Red highlight).
- **Notifications**: Daily notification at 7 AM to check the dashboard.

## Setup Instructions

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Firebase Setup**:
   This app uses Firebase Firestore. You must configure it for your project.
   
   - Install CLI: `npm install -g firebase-tools` & `dart pub global activate flutterfire_cli`
   -  Login: `firebase login`
   - Configure:
     ```bash
     flutterfire configure
     ```
     (Select your project and platforms, this will overwrite `lib/firebase_options.dart` with correct keys).

3. **Run the App**:
   ```bash
   flutter run
   ```

## Key Files

- `lib/main.dart`: Entry point, notification setup.
- `lib/services/database_service.dart`: Firestore logic & Urgent task checker.
- `lib/screens/dashboard_screen.dart`: Main UI.
- `lib/widgets/task_card.dart`: Task display & action buttons.

## Requirements
- Flutter SDK
- Firebase Account
