# Gym Management System

A comprehensive gym management application built with Flutter and Django.

## Features

- **Member Management**: Add, edit, and track gym members
- **Attendance Tracking**: QR code-based attendance system with real-time monitoring
- **Payment Management**: Handle membership payments and subscriptions
- **Trainer Management**: Manage gym trainers and their assignments
- **Equipment Management**: Track gym equipment and maintenance
- **Dashboard Analytics**: View comprehensive gym statistics and insights

## Tech Stack

### Frontend (Flutter)
- **Framework**: Flutter 
- **State Management**: Provider pattern
- **Authentication**: Google Sign-In integration
- **Security**: JWT token management, secure storage
- **Platforms**: Android, iOS, Web

### Backend (Django)
- **Framework**: Django REST Framework
- **Database**: PostgreSQL
- **Authentication**: JWT tokens, Google OAuth
- **API**: RESTful API with pagination and throttling

## Project Structure

```
gym-management-system/
├── gym_frontend/          # Flutter application
│   ├── lib/
│   │   ├── models/        # Data models
│   │   ├── providers/     # State management
│   │   ├── screens/       # UI screens
│   │   ├── services/      # API and business logic
│   │   ├── widgets/       # Reusable UI components
│   │   ├── utils/         # Utility functions
│   │   └── security/      # Security related code
│   ├── android/           # Android-specific files
│   ├── ios/              # iOS-specific files
│   └── web/              # Web-specific files
├── gym_backend/          # Django backend
│   ├── gym_api/          # Main API application
│   │   ├── models.py     # Database models
│   │   ├── views.py      # API endpoints
│   │   ├── serializers.py # Data serializers
│   │   └── urls.py       # URL routing
│   └── gym_backend/      # Django project settings
└── README.md             # This file
```

## Setup Instructions

### Backend Setup
1. Navigate to the backend directory
   ```bash
   cd gym_backend
   ```

2. Install dependencies
   ```bash
   pip install -r requirements.txt
   ```

3. Run migrations
   ```bash
   python manage.py migrate
   ```

4. Start the development server
   ```bash
   python manage.py runserver
   ```

### Frontend Setup
1. Navigate to the frontend directory
   ```bash
   cd gym_frontend
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Run the application
   ```bash
   flutter run
   ```

## Key Features

### Attendance System
- QR code-based check-in/check-out
- Real-time attendance tracking
- Historical attendance reports
- Cross-platform synchronization

### Member Management
- Comprehensive member profiles
- Membership plans and subscriptions
- Payment tracking and history
- Member search and filtering

### Analytics Dashboard
- Daily attendance statistics
- Revenue tracking
- Member engagement metrics
- Equipment usage analytics

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is proprietary software developed for gym management purposes.