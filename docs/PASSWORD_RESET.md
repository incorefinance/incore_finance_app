# Password Reset Flow

This document describes the password reset implementation in the Incore Finance app.

## Overview

Users can request a password reset email from the sign in screen. The reset link opens the app via a deep link and navigates directly to the reset password screen where users can set a new password.

## User Flow

1. User taps "Forgot password?" on the sign in screen
2. User enters their email address on the ForgotPasswordScreen
3. App sends a reset email via Supabase (does not reveal if email exists)
4. User clicks the link in their email
5. App opens via deep link and navigates to ResetPasswordScreen
6. User enters and confirms a new password
7. After success, user is routed back to sign in

## Screens

### ForgotPasswordScreen

Located at: `lib/presentation/auth/forgot_password_screen.dart`

Features:
- Single email input field
- "Send Reset Email" button
- Success message does not reveal whether the email exists
- Back navigation to sign in

### ResetPasswordScreen

Located at: `lib/presentation/auth/reset_password_screen.dart`

Features:
- New password and confirm password fields
- Password policy validation (minimum 12 characters)
- Inline error messages for validation and mismatch
- Session check with user friendly guidance if expired
- "Update Password" button
- After success, navigates to StartupScreen

## Deep Link Handling

The DeepLinkService detects recovery links and emits a `DeepLinkAction.recovery` action.

### URL Formats Handled

Fragment based (implicit flow):
```
incore-dev://auth-callback#access_token=...&type=recovery
```

Query based (PKCE flow):
```
incore-dev://auth-callback?code=...&type=recovery
```

### Navigation

In `main.dart`, a subscription to `DeepLinkService.onAction` listens for recovery actions and navigates to `AppRoutes.resetPassword` using the global navigator key.

## Supabase API Usage

### Requesting Reset Email

```dart
await supabase.auth.resetPasswordForEmail(
  email,
  redirectTo: 'incore-dev://auth-callback',
);
```

### Updating Password

After the deep link sets the session:

```dart
await supabase.auth.updateUser(
  UserAttributes(password: newPassword),
);
```

## Security Considerations

- The forgot password screen does not reveal whether an email exists in the system
- Rate limiting errors are shown to users to prevent abuse
- Password policy requires minimum 12 characters
- Session validation occurs before allowing password update

## Routes

| Route | Screen |
|-------|--------|
| `/forgot-password` | ForgotPasswordScreen |
| `/reset-password` | ResetPasswordScreen |

## Supabase Dashboard Configuration

Ensure the redirect URL is added to your Supabase project:

1. Go to Authentication > URL Configuration
2. Add `incore-dev://auth-callback` to the redirect URLs list

## Testing

1. From sign in screen, tap "Forgot password?"
2. Enter an email address and tap "Send Reset Email"
3. Verify success message appears (regardless of whether email exists)
4. Check email inbox for reset link
5. Click the link and verify app opens to ResetPasswordScreen
6. Enter new password (minimum 12 characters) and confirm
7. Tap "Update Password" and verify success
8. Verify navigation to sign in screen
9. Sign in with the new password
