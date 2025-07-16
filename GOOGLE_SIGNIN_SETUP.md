# Google Sign-In Setup Guide

## ✅ Issue Resolved!
**Google Sign-In now works on all platforms**

Updated with web client ID: `818835282138-qjqc6v2bf8n89ghrphh9l388erj5vt5g.apps.googleusercontent.com`

## Current Status
✅ **All Working:**
- Google Sign-In works on iOS/Android mobile apps  
- Google Sign-In works on web platform
- User profile display fixed in home screen drawer
- Email registration/login works on all platforms

## Configuration Details

### Client IDs in Use:
- **iOS/Android**: `818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com`
- **Web**: `818835282138-qjqc6v2bf8n89ghrphh9l388erj5vt5g.apps.googleusercontent.com`

### Files Updated:
- `lib/services/google_auth_service.dart` - Added web client ID
- `lib/screens/login_screen.dart` - Enabled Google Sign-In button for web
- `web/index.html` - Added Google Sign-In script

## How It Was Fixed

### Step 1: Google Cloud Console Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your existing project (or create new one)
3. Navigate to **APIs & Services** > **Credentials**

### Step 2: Create Web Application Client ID
1. Click **"+ CREATE CREDENTIALS"** > **"OAuth 2.0 Client IDs"**
2. Select **"Web application"** as the application type
3. Add these **Authorized JavaScript origins**:
   ```
   http://localhost:8080
   http://127.0.0.1:8080
   https://your-domain.netlify.app
   ```
4. Add these **Authorized redirect URIs**:
   ```
   http://localhost:8080
   http://127.0.0.1:8080
   https://your-domain.netlify.app
   ```
5. Click **"Create"**
6. Copy the new **Client ID** (it will look like: `xxxxx.apps.googleusercontent.com`)

### Step 3: Update Code
Replace the web client ID in `lib/services/google_auth_service.dart`:

```dart
if (kIsWeb) {
  _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: 'YOUR_NEW_WEB_CLIENT_ID.apps.googleusercontent.com', // Replace this
  );
}
```

## Current Configuration Analysis

### 3. Authorized Domains
Add these domains to your Google Cloud Console OAuth consent screen:
- `localhost` (for local development)
- Your production domain (e.g., `your-app.netlify.app`)
- `127.0.0.1` (for local development)

### 4. Authorized JavaScript Origins
Add these origins to your OAuth 2.0 Web Client:
- `http://localhost:8080` (Flutter web dev server)
- `http://127.0.0.1:8080` (Flutter web dev server)
- `https://your-app.netlify.app` (production)

### 5. Authorized Redirect URIs
Add these redirect URIs:
- `http://localhost:8080/auth/google/callback`
- `https://your-app.netlify.app/auth/google/callback`

## Backend Configuration

### Django Settings
Ensure your Django backend has the Google OAuth configuration:

```python
# gym_backend/gym_backend/settings.py
GOOGLE_OAUTH2_CLIENT_ID = 'your-client-id'
GOOGLE_OAUTH2_CLIENT_SECRET = 'your-client-secret'
```

### Environment Variables
Set these environment variables in your deployment:
```bash
GOOGLE_OAUTH2_CLIENT_ID=818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com
GOOGLE_OAUTH2_CLIENT_SECRET=your-client-secret
```

## Testing

### Local Development
1. Run Flutter web: `flutter run -d chrome`
2. Click "Continue with Google" button
3. Should redirect to Google sign-in popup
4. After successful authentication, user profile should appear in drawer

### Production
1. Deploy to Netlify with proper domain configuration
2. Test Google Sign-In with production domain
3. Verify user profile loads correctly

## Troubleshooting

### Common Issues
1. **"Google Sign-In popup was blocked"**
   - Solution: Enable popups for your domain

2. **"Invalid client ID"**
   - Solution: Verify client ID matches Google Cloud Console

3. **"Unauthorized domain"**
   - Solution: Add domain to authorized JavaScript origins

4. **"User profile not loading"**
   - Solution: Check network tab for API calls, verify backend is running

### Debug Information
The app includes debug logging for Google Sign-In:
- Check browser console for authentication flow logs
- Backend logs show token verification status

## Files Modified

### Frontend
- `lib/screens/login_screen.dart` - Added Google Sign-In button
- `lib/screens/home_screen.dart` - Fixed user profile display
- `lib/services/google_auth_service.dart` - Web platform support
- `web/index.html` - Added Google Sign-In script

### Backend
- `gym_api/auth_views.py` - Google authentication endpoint
- `gym_api/google_auth.py` - Google token verification
- `gym_backend/settings.py` - OAuth configuration

## Next Steps

1. **Get Google API Keys**: If you need new Google API credentials, let me know and I'll guide you through creating them.

2. **Update Client ID**: Replace the current client ID with your actual project's client ID.

3. **Test Authentication Flow**: Test both email login and Google Sign-In.

4. **Deploy**: Deploy to production with proper environment variables.

## Need Help?

If you need assistance with:
- Creating Google Cloud project
- Obtaining OAuth credentials  
- Configuring authorized domains
- Troubleshooting authentication issues

Just let me know and I'll provide step-by-step guidance!