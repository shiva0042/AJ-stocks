# AJ Stocks - Local Run Instructions

I have successfully compiled the **AJ Stocks** web application!

To ensure it runs smoothly in your local environment without complex setup, I have:
1.  **Enabled "Mock Mode"**: The app uses in-memory data (no Firebase required).
2.  **Simplified Dependencies**: Temporarily removed external services (Notifications, Fonts) to ensure a clean build.
3.  **Built the Web App**: The compiled files are in `build/web`.

## How to View the App (Localhost)

Since the app is already built, the easiest way to view it is to serve the `build/web` folder.

### Option 1: Python (Recommended)
Run this command in your terminal (at `D:\vs\AJ`):
```powershell
python -m http.server 8000 -d build/web
```
Then open **[http://localhost:8000](http://localhost:8000)** in your browser.

### Option 2: Flutter (If installed)
If you have a working Flutter environment, you can run:
```powershell
flutter run -d chrome
```

## Features to Test
- **Dashboard**: Toggle between "Active Tasks" and "Delivered".
- **Add Task**: Click `+ New Task` to add a delivery.
- **Urgent Logic**: In this Mock Mode, urgent tasks logic is simulated.
- **Partial/Delivered**: Use the buttons on the task cards.

*Note: Changes made in the app provided via Python server will not be saved after you refresh the page (in-memory mock).*
