#!/usr/bin/env python3

# Fix 1: password_validator.dart - convert score to int
print("Fixing password_validator.dart...")
with open('lib/services/password_validator.dart', 'r') as f:
    content = f.read()

content = content.replace(
    'final score = result.score; // 0-4',
    'final score = (result.score ?? 0).toInt(); // 0-4, convert from num to int'
)

with open('lib/services/password_validator.dart', 'w') as f:
    f.write(content)
print('✓ Fixed password_validator.dart')

# Fix 2 & 3 & 4: auth_form.dart
print("Fixing auth_form.dart...")
with open('lib/presentation/auth/widgets/auth_form.dart', 'r') as f:
    content = f.read()

# Fix 2: Update password field decoration
content = content.replace(
    '''decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_isSignUpMode) {
                  // For sign up, enforce strong password requirements
                  return PasswordValidator.validate(value ?? '');
                } else {
                  // For sign in, basic validation
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                }
                return null;
              },''',
    '''decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'At least ${PasswordValidator.minLength} characters',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (_isSignUpMode) {
                  // For sign up, enforce password policy
                  final policyResult = PasswordValidator.validatePolicy(value);
                  if (!policyResult.isValid) {
                    return policyResult.errorMessage;
                  }
                }
                return null;
              },'''
)

# Fix 4: Update PasswordStrengthIndicator widget call
content = content.replace(
    '''if (_isSignUpMode)
              PasswordStrengthIndicator(password: _passwordController.text),''',
    '''if (_isSignUpMode)
              PasswordStrengthIndicator(
                password: _passwordController.text,
                email: _emailController.text.trim(),
              ),'''
)

with open('lib/presentation/auth/widgets/auth_form.dart', 'w') as f:
    f.write(content)
print('✓ Fixed auth_form.dart')

print("\n✅ All fixes applied!")
