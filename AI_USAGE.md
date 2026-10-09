# AI usage declaration

This file records where AI assistance was used on this project. Each entry
says what the assistance covered and what the team did with it.

---

### Persistent local storage

**AI tool:** Claude / AI Assistant
**Purpose:** Technical guidance
**Area:** Persistent local storage

We sought AI assistance to help us navigate how to implement persistent local
storage in our frontend-only application. The assistance was used to
understand suitable  storage approaches on Flutter, structure
the persistence layer, handle data loading and saving, and consider persistence
testing. The implementation was reviewed and integrated into the project by the
team.

What we took from that guidance and built:

- `SharedPreferences` rather than `sqflite`, because both of our collections
  are always read in full and never queried relationally, so a key-value store
  holding two JSON documents avoids a schema and migrations we would not use.
- A single persistence layer in `lib/services/storage_service.dart` instead of
  storage calls scattered through widgets, so changing the backing store later
  is a one-file job.
- Namespaced keys collected in one `StorageKeys` class — `sla_tracker.tasks.v1`,
  `sla_tracker.members.v1`, `sla_tracker.session.current_user_id`,
  `sla_tracker.settings.theme_mode` — rather than generic names, so two
  features cannot collide and the `.v1` suffix leaves room to migrate.
- Repositories (`TaskRepository`, `MemberRepository`, `SessionRepository`) that
  hold the data in memory and mirror every mutation to disk, loaded once in
  `main()` before the first frame.
- Defensive reads: a missing key returns an empty list, malformed JSON is
  caught rather than thrown, an unparseable date falls back instead of
  crashing, and an unrecognised enum value resolves to a safe default. One bad
  record cannot stop the app starting.

---

