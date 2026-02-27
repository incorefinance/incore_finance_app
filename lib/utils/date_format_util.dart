/// Formats a [DateTime] as an ISO-8601 date string (YYYY-MM-DD).
///
/// Shared utility to replace inline date formatting patterns
/// used across models, services, and presentation layers.
String toIsoDateString(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
