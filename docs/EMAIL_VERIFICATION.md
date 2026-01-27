# Email Verification

This document describes the email verification enforcement implemented in the Incore Finance app.

## Overview

Users who sign up with email/password must verify their email address before accessing the onboarding flow or dashboard. This prevents unauthorized access and ensures valid email addresses.

## Gating Rule

The verification check occurs in `StartupScreen._handleAuthenticatedUser()`:

1. If the user is authenticated but `user.emailConfirmedAt == null`, they are routed to `/email-verification`
2. The navigation uses `pushNamedAndRemoveUntil` to clear the stack, preventing back navigation bypass
3. Only after email verification can users proceed to onboarding or dashboard

## Email Verification Screen

Located at: `lib/presentation/auth/email_verification_screen.dart`

Features:
- Displays the user's email address
- "Resend Verification Email" button with 60 second cooldown
- "I Have Verified, Refresh" button to manually check verification status
- Sign out option in the app bar
- Listens to auth state changes for automatic routing when verified

## Resend Cooldown

The resend button has a 60 second rate limit to prevent abuse:

- Cooldown is persisted to SharedPreferences using key `email_verification_last_resend_at`
- Stores epoch milliseconds of last resend
- On screen load, calculates remaining cooldown from persisted value
- Displays countdown timer when active (e.g., "Resend Email (45 s)")
- Survives app restarts

## Deep Link Handling

Deep links allow the app to process Supabase verification links directly.

### How It Works

1. `DeepLinkService` initializes in `main.dart` before the app starts
2. Handles both cold start (app opened via link) and warm start (link received while running)
3. Parses Supabase auth tokens from URL fragments or query parameters
4. Sets the session using `supabase.auth.setSession()` or `getSessionFromUrl()`
5. Emits an event via `onAuthUpdate` stream for UI refresh

### Supported URL Formats

Fragment based (implicit flow):
```
incore://auth-callback#access_token=...&refresh_token=...&type=signup
```

Query based (PKCE flow):
```
incore://auth-callback?code=...
```

## Supabase Dashboard Configuration

### 1. Enable Email Confirmations

In your Supabase project dashboard:
1. Go to Authentication > Providers > Email
2. Enable "Confirm email"

### 2. Configure Redirect URLs

Go to Authentication > URL Configuration and add your redirect URLs:

**Development (Custom Scheme):**
```
incore://auth-callback
```

**Production (HTTPS):**
```
https://your-domain.com/auth-callback
```

### 3. Email Template (Optional)

Customize the confirmation email template at Authentication > Email Templates > Confirm signup.

The `{{ .ConfirmationURL }}` variable will contain the verification link.

## Platform Configuration

### Android

Add the following intent filter to `android/app/src/main/AndroidManifest.xml` inside the `<activity>` tag:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="incore" android:host="auth-callback" />
</intent-filter>
```

For HTTPS links (App Links), additional configuration is required:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="your-domain.com" android:pathPrefix="/auth-callback" />
</intent-filter>
```

### iOS

Add the following to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>incore</string>
        </array>
    </dict>
</array>
```

For Universal Links (HTTPS), add:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:your-domain.com</string>
</array>
```

And host an `apple-app-site-association` file at `https://your-domain.com/.well-known/apple-app-site-association`.

## Changing the Deep Link Scheme

The scheme is defined in `lib/services/deep_link_service.dart`:

```dart
const String kDeepLinkScheme = 'incore';
```

If you change this value, update:
1. Android manifest intent filter
2. iOS Info.plist URL schemes
3. Supabase redirect URLs in dashboard

## Testing

1. Sign up with a new email address
2. Verify you are routed to the email verification screen
3. Check that the "Resend" button works and shows cooldown
4. Click the verification link in the email
5. Verify the app opens and routes to onboarding/dashboard
6. Test the "I Have Verified, Refresh" button after verifying externally

## Troubleshooting

**Link does not open app:**
- Verify the scheme matches in all configurations
- On Android, ensure the intent filter is inside the main `<activity>` tag
- On iOS, check that the URL scheme is properly registered

**Session not updating after link click:**
- Check Supabase logs for errors
- Verify the redirect URL is in the allowed list in Supabase dashboard
- Ensure tokens are being parsed correctly from the URL

**Cooldown not persisting:**
- Verify SharedPreferences is working correctly
- Check for storage permission issues on the device
