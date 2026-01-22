# Color Migration Mapping

## Old AppTheme Constants → New AppColors Tokens

This document maps the old color constants from the `AppTheme` class to the new
product specific `AppColors` token system.

The goal is to fully decouple the app visual identity from Incore corporate
branding and move to a lighter, calmer, fintech oriented palette.

---

## ⚠️ No Compatibility Layer

There is **no compatibility layer**.

All files referencing old `AppTheme` color constants **must be updated** to use
`AppColors` tokens directly.

---

## ### Primary and Brand Colors

| Old Name | New Token | Hex Value | Usage |
|---------|-----------|-----------|-------|
| `AppTheme.primaryNavyLight` | `AppColors.primary` | `#036D9A` | Primary actions, buttons, active states |
| `AppTheme.primaryNavyDark` | `AppColors.textPrimary` | `#253E4C` | Dark anchor for text, icons, headers |
| `AppTheme.accentGold` | `AppColors.primarySoft` | `#6EABC6` | Secondary accents, highlights |
| `AppTheme.accentGoldLight` | `AppColors.primaryTint` | `#E6F2F7` | Subtle tinted backgrounds |

Notes:
- Old names reflect Incore branding and are intentionally removed
- Avoid using dark anchors as full screen backgrounds

---

## ### Background and Surface Colors

| Old Name | New Token | Hex Value | Usage |
|---------|-----------|-----------|-------|
| `AppTheme.backgroundLight` | `AppColors.canvas` | `#F7FAFC` | Main app canvas |
| `AppTheme.surfaceLight` | `AppColors.surface` | `#FFFFFF` | Cards, dialogs, sheets |
| `AppTheme.cardLight` | `AppColors.surface` | `#FFFFFF` | Card backgrounds |

Dark theme mappings depend on existing tokens:
- `AppTheme.backgroundDark` → `AppColors.backgroundDark`
- `AppTheme.surfaceDark` → `AppColors.surfaceDark`
- `AppTheme.cardDark` → `AppColors.surfaceDark`

---

## ### Text Colors

| Old Name | New Token | Hex Value | Usage |
|---------|-----------|-----------|-------|
| `AppTheme.textPrimary` | `AppColors.textPrimary` | `#253E4C` | High emphasis text |
| `AppTheme.textSecondary` | `AppColors.textSecondary` | `#5F7A89` | Medium emphasis text |

If defined in `AppColors`:
- `AppTheme.textPrimaryDark` → `AppColors.textPrimaryDark`
- `AppTheme.textSecondaryDark` → `AppColors.textSecondaryDark`

Do not invent dark text hex values if tokens do not exist.

---

## ### Semantic Colors

| Old Name | New Token | Hex Value | Usage |
|---------|-----------|-----------|-------|
| `AppTheme.successGreen` | `AppColors.success` | `#6FB3A2` | Success states |
| `AppTheme.warningAmber` | `AppColors.warning` | `#E0A458` | Warning states |
| `AppTheme.errorRed` | `AppColors.error` | `#D16C6C` | Errors, destructive actions |

Financial semantics:
- Use `AppColors.income` (`#4F9E8F`) for income
- Use `AppColors.expense` (`#D16C6C`) for expenses

---

## ### Borders and Dividers

| Old Name | New Token | Hex Value | Usage |
|---------|-----------|-----------|-------|
| `AppTheme.neutralGray` | `AppColors.borderSubtle` | `#E5EDF2` | Borders and dividers |
| `AppTheme.dividerLight` | `AppColors.borderSubtle` | `#E5EDF2` | Section separators |

If present:
- `AppTheme.dividerDark` → `AppColors.dividerDark`

---

## ### Shadow Colors

Only map these if shadow tokens exist in `AppColors`.

| Old Name | New Token | Usage |
|---------|-----------|-------|
| `AppTheme.shadowLight` | `AppColors.shadowLight` | Light theme elevation |
| `AppTheme.shadowDark` | `AppColors.shadowDark` | Dark theme elevation |

---

## New Tokens Added

These tokens have no old equivalents.

| Token | Hex Value | Usage |
|------|-----------|-------|
| `AppColors.calmSupport` | `#BCD4CC` | Calm background accents |
| `AppColors.textTertiary` | `#9BB1BC` | Low emphasis text |
| `AppColors.textDisabled` | `#C7D4DC` | Disabled states |
| `AppColors.income` | `#4F9E8F` | Income indicators |
| `AppColors.expense` | `#D16C6C` | Expense indicators |

---

## Typography Migration

All typography has moved from **Inter** to **Manrope**.

```dart
// Before
GoogleFonts.inter(...)

// After
GoogleFonts.manrope(...)

This applies to all text styles in:
- TextTheme (_buildTextTheme)
- AppBarTheme
- ButtonThemes (ElevatedButton, OutlinedButton, TextButton)
- BottomNavigationBarTheme
- InputDecorationTheme
- TabBarTheme
- TooltipTheme
- DialogTheme
- SliderTheme
- SnackBarTheme

## Migration Instructions for Other Files

To migrate files that reference the old `AppTheme` color constants:

1. **Import the new colors file**:
   ```dart
   import 'package:incore_finance/theme/app_colors.dart';
   ```

2. **Replace color references** using the mapping table above

3. **Common patterns**:
   ```dart
   // Before
   color: AppTheme.primaryNavyLight

   // After
   color: AppColors.primary
   ```

4. **Font references**:
   ```dart
   // Before
   style: TextStyle(fontFamily: GoogleFonts.inter().fontFamily)

   // After
   style: TextStyle(fontFamily: GoogleFonts.manrope().fontFamily)
   ```

## Compilation Risks

### No Compatibility Layer

There is **no compatibility layer**. All files referencing old `AppTheme` color constants must be updated to use `AppColors` tokens.

### Breaking Changes

Files that will need updates:
- Any widget or screen referencing `AppTheme.primaryNavyLight`, `AppTheme.accentGold`, etc.
- Custom widgets that hardcode color values
- Chart widgets that reference theme colors directly

### Recommended Fix Strategy

1. Search codebase for `AppTheme.primary`, `AppTheme.accent`, etc.
2. Use find-and-replace with the mapping table above
3. Test each screen visually after migration
4. Run `flutter analyze` to catch compile errors
5. Use IDE's "Find Usages" feature to locate all references

## Dark Theme Considerations

Dark theme uses different color assignments:
- Primary accent is now `AppColors.warning` (warm tone for dark backgrounds)
- Preserved existing `backgroundDark` and `surfaceDark` values for consistency
- Text colors use the preserved dark theme tokens

## Notes

- Layout values, paddings, radii, elevations remain unchanged
- Material 3 ThemeData structure preserved
- No changes to animation curves, durations, or spacing constants
- All semantic color usage (success, warning, error) updated to new palette
