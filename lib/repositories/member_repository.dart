import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/team_member.dart';
import '../services/seed_data.dart';
import '../services/storage_service.dart';

/// Thrown for sign-up / sign-in problems the user can fix, with a message that
/// is safe to show on screen.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Single source of truth for the team roster.
///
/// Mirrors [TaskRepository]: an in-memory list that is written straight back
/// to local storage on every change.
class MemberRepository {
  MemberRepository._();

  static final MemberRepository instance = MemberRepository._();

  final List<TeamMember> _members = [];
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;

    final storage = StorageService.instance;
    if (!storage.containsKey(StorageKeys.members)) {
      _members
        ..clear()
        ..addAll(SeedData.members());
      await _persist();
    } else {
      _members
        ..clear()
        ..addAll(
          storage.readJsonList(StorageKeys.members).map(TeamMember.fromJson),
        );
    }
    _loaded = true;
  }

  List<TeamMember> get all => List.unmodifiable(_members);

  /// Looks a member up by id. Returns null for an unassigned task or for a
  /// member who has since been removed, so callers must handle the empty case.
  TeamMember? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final member in _members) {
      if (member.id == id) return member;
    }
    return null;
  }

  /// Case-insensitive email lookup. Returns null when nobody has that email.
  TeamMember? byEmail(String email) {
    final wanted = _normalise(email);
    for (final member in _members) {
      if (_normalise(member.email) == wanted) return member;
    }
    return null;
  }

  Future<void> save(TeamMember member) async {
    final index = _members.indexWhere((existing) => existing.id == member.id);
    if (index == -1) {
      _members.add(member);
    } else {
      _members[index] = member;
    }
    await _persist();
  }

  /// Creates a new account and adds the person to the roster.
  ///
  /// Throws [AuthException] if the email already belongs to someone.
  Future<TeamMember> register({
    required String name,
    required String email,
    required String password,
    String role = 'Team member',
    String colorKey = 'blue',
  }) async {
    if (byEmail(email) != null) {
      throw const AuthException('An account with this email already exists.');
    }

    final id = newId();
    final member = TeamMember(
      id: id,
      name: name.trim(),
      role: role,
      email: _normalise(email),
      colorKey: colorKey,
      passwordHash: _hash(id, password),
    );
    await save(member);
    return member;
  }

  /// Returns the member when the email and password match, otherwise null.
  /// Members without a stored password can never be authenticated.
  TeamMember? authenticate(String email, String password) {
    final member = byEmail(email);
    if (member == null || member.passwordHash.isEmpty) return null;
    return member.passwordHash == _hash(member.id, password) ? member : null;
  }

  /// Removes a member from the roster.
  ///
  /// This deliberately does nothing about the tasks they owned - that is the
  /// caller's decision, and the Team screen makes it explicitly by calling
  /// `TaskRepository.unassignAll` first. Keeping the two separate means this
  /// repository never reaches across into the other one's data.
  Future<void> delete(String id) async {
    _members.removeWhere((member) => member.id == id);
    await _persist();
  }

  String newId() => 'member_${DateTime.now().microsecondsSinceEpoch}';

  String _normalise(String email) => email.trim().toLowerCase();

  /// Salted with the member id so two people with the same password do not
  /// share a hash. This is local-only convenience hashing, not a substitute
  /// for server-side password storage.
  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  Future<void> _persist() => StorageService.instance.writeJsonList(
        StorageKeys.members,
        _members.map((member) => member.toJson()).toList(),
      );

  void resetForTesting() {
    _members.clear();
    _loaded = false;
  }
}