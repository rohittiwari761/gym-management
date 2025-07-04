# Gym Management System

A complete cross-platform gym management application built with Django backend and Flutter frontend.

## Features

- **Member Management**: Track gym members, their memberships, and personal information
- **Trainer Management**: Manage trainers, their specializations, and availability
- **Equipment Management**: Monitor gym equipment status and maintenance
- **Attendance System**: Check-in/check-out functionality for members
- **Workout Sessions**: Schedule and track workout sessions
- **Payment Tracking**: Record membership payments and history
- **Cross-Platform**: Works on Android, iOS, Web, and Desktop

## Project Structure

```
gym-management-system/
├── gym_backend/          # Django REST API backend
│   ├── gym_backend/      # Main Django project
│   ├── gym_api/          # API app with models, views, serializers
│   └── manage.py
├── gym_frontend/         # Flutter frontend
│   ├── lib/
│   │   ├── models/       # Data models
│   │   ├── providers/    # State management
│   │   ├── screens/      # UI screens
│   │   ├── services/     # API service
│   │   └── main.dart
│   └── pubspec.yaml
├── venv/                 # Python virtual environment
└── README.md
```

## Backend Setup (Django)

### Prerequisites
- Python 3.8+
- pip

### Installation

1. Navigate to the project directory:
   ```bash
   cd gym-management-system
   ```

2. Activate the virtual environment:
   ```bash
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Navigate to the backend directory:
   ```bash
   cd gym_backend
   ```

4. Run migrations:
   ```bash
   python manage.py migrate
   ```

5. Create a superuser (optional):
   ```bash
   python manage.py createsuperuser
   ```

6. Start the Django development server:
   ```bash
   python manage.py runserver
   ```

The backend API will be available at `http://127.0.0.1:8000/`

### API Endpoints

- **Members**: `/api/members/`
- **Trainers**: `/api/trainers/`
- **Equipment**: `/api/equipment/`
- **Workout Plans**: `/api/workout-plans/`
- **Exercises**: `/api/exercises/`
- **Workout Sessions**: `/api/workout-sessions/`
- **Payments**: `/api/payments/`
- **Attendance**: `/api/attendance/`

### Special Endpoints

- Available trainers: `/api/trainers/available/`
- Working equipment: `/api/equipment/working/`
- Upcoming sessions: `/api/workout-sessions/upcoming/`
- Check-in: `/api/attendance/check_in/`
- Check-out: `/api/attendance/check_out/`

## Frontend Setup (Flutter)

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+

### Installation

1. Navigate to the frontend directory:
   ```bash
   cd gym_frontend
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   
   **For Web:**
   ```bash
   flutter run -d chrome
   ```
   
   **For Mobile (iOS Simulator):**
   ```bash
   flutter run -d ios
   ```
   
   **For Mobile (Android Emulator):**
   ```bash
   flutter run -d android
   ```
   
   **For macOS Desktop:**
   ```bash
   flutter run -d macos
   ```

### Flutter Configuration

The Flutter app is configured to connect to the Django backend at `http://127.0.0.1:8000/api`. Make sure the Django server is running before starting the Flutter app.

## Usage

1. **Start the Backend**: Run the Django server first
2. **Start the Frontend**: Run the Flutter app on your preferred platform
3. **Navigate**: Use the bottom navigation to access different features:
   - Dashboard: Overview of gym statistics
   - Members: View and manage gym members
   - Trainers: View and manage trainers
   - Equipment: Monitor gym equipment
   - Attendance: Check members in/out

## Models

### Member
- User information (name, email, username)
- Phone number and emergency contact
- Membership type (Basic, Premium, VIP)
- Join date and membership expiry
- Active status

### Trainer
- User information
- Specialization (Fitness, Yoga, Cardio, etc.)
- Experience years and certification
- Hourly rate and availability status

### Equipment
- Name, type, and brand
- Purchase date and warranty
- Working status and maintenance notes

### Workout Session
- Member and trainer assignment
- Date, duration, and completion status
- Session notes

### Attendance
- Daily check-in/check-out tracking
- Member attendance history

## Cross-Platform Support

This application supports:
- **Android**: Native mobile app
- **iOS**: Native mobile app  
- **Web**: Progressive web app
- **macOS**: Desktop application
- **Windows**: Desktop application (with Flutter desktop support)
- **Linux**: Desktop application (with Flutter desktop support)

## Development

To extend the application:

1. **Backend**: Add new models in `gym_api/models.py`, create serializers, and add viewsets
2. **Frontend**: Create new screens in `lib/screens/`, add models in `lib/models/`, and update the API service

## Dependencies

### Backend (Django)
- Django 4.2+
- Django REST Framework
- django-cors-headers

### Frontend (Flutter)
- http: API requests
- provider: State management
- intl: Date formatting
- shared_preferences: Local storage

## Notes

- The backend uses SQLite database for development
- CORS is enabled for cross-origin requests from Flutter
- All API endpoints support CRUD operations
- The Flutter app uses Provider for state management
- Error handling is implemented throughout the application