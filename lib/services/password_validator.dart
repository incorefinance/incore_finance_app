import 'package:zxcvbn/zxcvbn.dart';

/// Result of password policy validation (enforced).
class PolicyValidationResult {
  final bool isValid;
  final String? errorMessage;

  PolicyValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}

/// Result of password strength evaluation (advisory, not enforced).
class PasswordStrengthResult {
  final int score; // 0-4 (from zxcvbn)
  final String label; // Very weak, Weak, Fair, Strong, Very strong
  final String? feedback; // Optional suggestion from zxcvbn

  PasswordStrengthResult({
    required this.score,
    required this.label,
    this.feedback,
  });
}

/// Modern password validation service following 2024-2026 best practices.
/// 
/// Policy (enforced):
/// - Minimum 12 characters
/// - Maximum 128 characters
/// - Allow almost any character (only blocks null \u0000 and newlines \n, \r)
/// - Allow Unicode (e.g., accented characters for Portuguese passphrases)
/// 
/// Strength (advisory):
/// - Uses zxcvbn algorithm (industry standard)
/// - Detects common passwords, patterns, keyboard sequences, l33t speak
/// - Downgraded by personal info matching (email, name substrings)
/// - Score 0-4: Very weak → Very strong
class PasswordValidator {
  static const int minLength = 12;
  static const int maxLength = 128;

  /// Validates password against policy requirements (enforced gate).
  /// Returns PolicyValidationResult with isValid=true if all requirements met.
  static PolicyValidationResult validatePolicy(String password) {
    if (password.isEmpty) {
      return PolicyValidationResult(
        isValid: false,
        errorMessage: 'Please enter your password',
      );
    }

    if (password.length < minLength) {
      return PolicyValidationResult(
        isValid: false,
        errorMessage:
            'Password must be at least $minLength characters',
      );
    }

    if (password.length > maxLength) {
      return PolicyValidationResult(
        isValid: false,
        errorMessage:
            'Password must be $maxLength characters or less',
      );
    }

    // Block null and newline characters
    if (password.contains('\u0000') ||
        password.contains('\n') ||
        password.contains('\r')) {
      return PolicyValidationResult(
        isValid: false,
        errorMessage: "Password can't contain line breaks or null characters",
      );
    }

    return PolicyValidationResult(isValid: true);
  }

  /// Evaluates password strength using zxcvbn algorithm (advisory, not enforced).
  /// 
  /// Parameters:
  /// - password: The password to evaluate
  /// - email: Optional email to detect personal info (will downgrade strength if found)
  /// - name: Optional name to detect personal info (will downgrade strength if found)
  /// 
  /// Returns PasswordStrengthResult with score 0-4 and label.
  static PasswordStrengthResult evaluateStrength(
    String password, {
    String? email,
    String? name,
  }) {
    if (password.isEmpty) {
      return PasswordStrengthResult(
        score: 0,
        label: 'Very weak',
      );
    }

    // Use zxcvbn to get base score and feedback
    final zxcvbn = Zxcvbn();
    final result = zxcvbn.evaluate(
      password,
      userInputs: [
        if (email != null) email,
        if (name != null) name,
      ],
    );

    final score = result.score?.toInt() ?? 0; // 0-4
    final label = _scoreToLabel(score);
    final feedback =
        result.feedback.warning ?? result.feedback.suggestions?.join(', ');

    return PasswordStrengthResult(
      score: score,
      label: label,
      feedback: feedback,
    );
  }

  /// Converts zxcvbn score (0-4) to human-readable label.
  static String _scoreToLabel(int score) {
    switch (score) {
      case 0:
        return 'Very weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Strong';
      case 4:
        return 'Very strong';
      default:
        return 'Unknown';
    }
  }

  /// Gets color for strength score (red → yellow → green).
  static int getStrengthColor(int score) {
    switch (score) {
      case 0:
      case 1:
        return 0xFFE53935; // Red
      case 2:
        return 0xFFFB8C00; // Orange
      case 3:
        return 0xFFFDD835; // Yellow
      case 4:
        return 0xFF43A047; // Green
      default:
        return 0xFFF5F5F5; // Gray
    }
  }
}

