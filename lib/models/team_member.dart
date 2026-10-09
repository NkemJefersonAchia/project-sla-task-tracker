/// A person who can be assigned work.
///
/// The team roster doubles as the "user selection" list on the sign-in screen:
/// signing in simply means choosing which member you are.
class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.colorKey,
    this.passwordHash = '',
  });

  final String id;
  final String name;
  final String role;
  final String email;

  /// Name of an accent colour in `AppColors` (`blue`, `green`, `purple`...).
  /// Storing the *name* rather than an int keeps the JSON readable and lets
  /// the same member render correctly in both light and dark theme.
  final String colorKey;

  /// Hash of the member's password, set at sign up. Empty for members that
  /// were never given a password (for example the seeded roster), which means
  /// they cannot sign in with a password until one is set.
  final String passwordHash;

  /// Up to two letters used by the avatar when there is no photo.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      final word = parts.first;
      return (word.length >= 2 ? word.substring(0, 2) : word).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  TeamMember copyWith({
    String? name,
    String? role,
    String? email,
    String? colorKey,
    String? passwordHash,
  }) {
    return TeamMember(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      colorKey: colorKey ?? this.colorKey,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'email': email,
        'colorKey': colorKey,
        'passwordHash': passwordHash,
      };

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Unknown',
        role: json['role'] as String? ?? '',
        email: json['email'] as String? ?? '',
        colorKey: json['colorKey'] as String? ?? 'gray',
        passwordHash: json['passwordHash'] as String? ?? '',
      );
}