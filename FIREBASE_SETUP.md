# Firebase Setup Guide for LetsPlay

Your Flutter project is already configured to use Firebase! Here's how to complete the setup:

## Prerequisites

- Firebase CLI installed: `npm install -g firebase-tools`
- Google account with Firebase project (`lets-play-app-9e8e0`)
- Flutterfire CLI installed: `dart pub global activate flutterfire_cli`

## Step 1: Enable Firebase Services in Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select project `lets-play-app-9e8e0`
3. Enable these services:
   - **Authentication**: Go to "Build" → "Authentication" → Click "Get started"
     - Enable "Email/Password" provider
   - **Cloud Firestore**: Go to "Build" → "Cloud Firestore" → Click "Create database"
     - Start in test mode (for development)
     - Choose your region (nearest to users)
   - **Storage** (optional): For file uploads
     - Go to "Build" → "Storage" → Click "Get started"

## Step 2: Generate Platform-Specific Configurations

Run the following command in your project root:

```bash
flutterfire configure --project=lets-play-app-9e8e0 --platforms=web,android,ios
```

This will automatically update `lib/services/firebase_options.dart` with correct credentials.

## Step 3: Verify Configuration

Your `firebase_options.dart` should now have valid configs for:
- ✅ Web
- ✅ Android
- ✅ iOS
- ⚠️ macOS/Windows/Linux (placeholders are OK for now)

## Step 4: Test Authentication

Run your app and test signup/login:

```bash
flutter run
```

### Test Signup:
1. Navigate to Sign Up page
2. Enter:
   - Email: `test@example.com`
   - Username: `testuser`
   - Password: `Test123456`
   - Fill other required fields
3. Click "Create Account"
4. Check Firebase Console → Authentication → Users to verify new user

### Test Login:
1. Go to Login page
2. Enter email and password from signup
3. Should navigate to home page

## Step 5: Firestore Database Rules

For **development only**, update Firestore rules to allow read/write:

Go to Firebase Console → Firestore → Rules tab, paste:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow reads/writes for authenticated users
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    match /users/{document=**} {
      allow read, write: if request.auth != null;
    }
    // Allow all reads/writes (FOR DEVELOPMENT ONLY - NOT PRODUCTION!)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Then publish the rules.

## Step 6: Test Firestore Database

After successful signup, verify user data is saved:

1. Go to Firebase Console
2. Navigate to "Cloud Firestore"
3. Check `users` collection
4. You should see your new user document with:
   - uid, email, username, metrics, etc.

## Step 7: Features Ready to Use

Your app now supports:

✅ **User Registration** - SignUp.dart with validation
✅ **User Login** - Login.dart with email auth
✅ **Forgot Password** - ForgotPassword.dart with email reset
✅ **User Profile** - Profile.dart displays user metrics
✅ **Database Storage** - All user data saved to Firestore
✅ **Performance Metrics** - Stored and displayed per user

## Troubleshooting

### Issue: "Firebase initialization failed"
**Solution**: Ensure `firebase_options.dart` has valid API keys from the console.

### Issue: "user-not-found" on login
**Solution**: Make sure email is registered via signup first.

### Issue: "Permission denied" on Firestore read/write
**Solution**: Check your Firestore rules allow authenticated users (see Step 5).

### Issue: Cannot create user - "email-already-in-use"
**Solution**: This is expected if you already signed up with that email. Use a different email.

## Security Checklist (Before Production)

- [ ] Update Firestore rules to proper security rules (not permissive)
- [ ] Enable Two-Factor Authentication in Firebase Console
- [ ] Set up Cloud Functions for sensitive operations
- [ ] Enable rate limiting for auth endpoints
- [ ] Use environment variables for API keys (not hardcoded)
- [ ] Test on real devices (not just emulator)
- [ ] Set up Firebase Monitoring and Alerts

## Next Steps

1. Run `flutterfire configure` if you haven't already
2. Test signup → login → logout flow
3. Verify user data in Firestore Console
4. Start building additional features!

---

**Need Help?**
- [Firebase Documentation](https://firebase.flutter.dev/)
- [Flutterfire Setup Guide](https://firebase.flutter.dev/docs/overview)
- [Firebase Console](https://console.firebase.google.com)
