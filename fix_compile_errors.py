import re

# Fix 1
with open('lib/services/password_validator.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r'final score = result\.score; // 0-4',
    'final score = (result.score ?? 0).toInt(); // 0-4, convert from num to int',
    content
)

with open('lib/services/password_validator.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('✓ password_validator.dart fixed')

# Fix 2
with open('lib/presentation/auth/widgets/auth_form.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace decoration + validator together
old_pattern = r'''decoration: const InputDecoration\(
                labelText: 'Password',
                border: OutlineInputBorder\(\),
              \),
              validator: \(value\) \{
                if \(_isSignUpMode\) \{
                  // For sign up, enforce strong password requirements
                  return PasswordValidator\.validate\(value \?\? ''\);
                \} else \{
                  // For sign in, basic validation
                  if \(value == null \|\| value\.isEmpty\) \{
                    return 'Please enter your password';
                  \}
                \}
                return null;
              \},'''

new_pattern = '''decoration: InputDecoration(
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

content = re.sub(old_pattern, new_pattern, content, flags=re.DOTALL)

# Replace PasswordStrengthIndicator
old_indicator = r'''if \(_isSignUpMode\)
              PasswordStrengthIndicator\(password: _passwordController\.text\),'''

new_indicator = '''if (_isSignUpMode)
              PasswordStrengthIndicator(
                password: _passwordController.text,
                email: _emailController.text.trim(),
              ),'''

content = re.sub(old_indicator, new_indicator, content, flags=re.DOTALL)

with open('lib/presentation/auth/widgets/auth_form.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('✓ auth_form.dart fixed')
print('✅ Done!')
