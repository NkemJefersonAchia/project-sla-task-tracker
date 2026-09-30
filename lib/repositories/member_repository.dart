import '../models/team_member.dart';
import '../services/seed_data.dart';
import '../services/storage_service.dart';

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

  Future<void> save(TeamMember member) async {
    final index = _members.indexWhere((existing) => existing.id == member.id);
    if (index == -1) {
      _members.add(member);
    } else {
      _members[index] = member;
    }
    await _persist();
  }

  // TODO(team): delete(String id) - removing a member must also decide what
  // happens to the tasks they own (unassign them, or block the delete).
  // Owned by the Team Members work stream, see TEAM_TASKS.md.

  String newId() => 'member_${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _persist() => StorageService.instance.writeJsonList(
        StorageKeys.members,
        _members.map((member) => member.toJson()).toList(),
      );

  void resetForTesting() {
    _members.clear();
    _loaded = false;
  }
}
