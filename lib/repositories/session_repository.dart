import '../models/team_member.dart';
import '../services/storage_service.dart';
import 'member_repository.dart';

/// Remembers which team member is currently signed in.
///
/// This is a *local* session, not real authentication - the assignment asks
/// for the interface and the flow, not a backend. The important behaviour is
/// that the choice survives a restart: storing the member id means the app
/// reopens on the dashboard instead of asking the user to sign in again.
class SessionRepository {
  SessionRepository._();

  static final SessionRepository instance = SessionRepository._();

  String? _currentUserId;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _currentUserId = StorageService.instance.readString(
      StorageKeys.currentUserId,
    );
    _loaded = true;
  }

  bool get isSignedIn => currentUser != null;

  /// The signed-in member, resolved fresh from [MemberRepository] so profile
  /// edits show up immediately without a second copy to keep in sync.
  TeamMember? get currentUser => MemberRepository.instance.byId(_currentUserId);

  Future<void> signIn(TeamMember member) async {
    _currentUserId = member.id;
    await StorageService.instance.writeString(
      StorageKeys.currentUserId,
      member.id,
    );
  }

  /// Clears the session only. Tasks and members stay on the device, which is
  /// what a user expects from "Sign out" rather than "Delete my data".
  Future<void> signOut() async {
    _currentUserId = null;
    await StorageService.instance.remove(StorageKeys.currentUserId);
  }
}
