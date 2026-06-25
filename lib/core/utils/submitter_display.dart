/// Seed / role labels — not real person names for "Added by" lines.
bool isRolePlaceholderSubmitterName(String name) {
  switch (name.trim().toLowerCase()) {
    case 'female editor':
    case 'male editor':
    case 'female gender admin':
    case 'male gender admin':
    case 'global admin':
      return true;
    default:
      return false;
  }
}

/// Name to show on submitter attribution, or null to hide the line.
String? resolveSubmitterLineName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty || isRolePlaceholderSubmitterName(trimmed)) {
    return null;
  }
  return trimmed;
}
