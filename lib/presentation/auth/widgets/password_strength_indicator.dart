import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/password_validator.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Password strength indicator widget showing:
/// - Section A: Policy requirement (enforced) - "At least 12 characters"
/// - Section B: Strength meter (advisory, not enforced) - zxcvbn score visualization
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final String? email;
  final String? name;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.email,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Policy validation (enforced)
    final policyResult = PasswordValidator.validatePolicy(password);
    final meetsPolicy = policyResult.isValid;
    final policyProgressValue = password.isEmpty
    ? 0.0
    : (password.length / PasswordValidator.minLength).clamp(0.0, 1.0);

    // Strength evaluation (advisory)
    final strengthResult = PasswordValidator.evaluateStrength(
      password,
      email: email,
      name: name,
    );
    final strengthColor = PasswordValidator.getStrengthColor(strengthResult.score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section A: Policy requirement (enforced)
        if (password.isNotEmpty) ...[
          SizedBox(height: 1.5.h),
          Text(
            'Password requirements:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 10.sp,
            ),
          ),
          SizedBox(height: 0.8.h),
          Row(
            children: [
              Icon(
                meetsPolicy
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 16,
                color: meetsPolicy ? Color(0xFF43A047) : Color(0xFFE53935),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'At least ${PasswordValidator.minLength} characters (${password.length}/${PasswordValidator.minLength})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: meetsPolicy ? colorScheme.onSurface : Color(0xFFE53935),
                    fontWeight: meetsPolicy ? FontWeight.w500 : FontWeight.w400,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          // Section B: Strength meter (advisory, not enforced)
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: LinearProgressIndicator(
                    value: strengthResult.score / 4.0,
                    minHeight: 0.8.h,
                    backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(strengthColor),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'Strength: ${strengthResult.label}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Color(strengthColor),
                  fontWeight: FontWeight.w600,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
          // Optional feedback hint
          if (strengthResult.feedback != null && strengthResult.feedback!.isNotEmpty) ...[
            SizedBox(height: 0.8.h),
            Text(
              strengthResult.feedback!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
                fontSize: 9.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ],
    );
  }
}

