import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// `BackupFileSystem` — the injected gateway to the three plugin-dependent
/// operations FEAT20 needs (`class-settings.drawio`). Mirrors `Clock`'s
/// established DI shape (`budgeting/clock.dart`): `flutter test` runs on the
/// host, where `share_plus`/`file_picker` platform-channel calls throw
/// `MissingPluginException`, exactly the testability problem `Clock` was
/// built to solve for `DateTime.now()`.
///
/// Only these three plugin calls are wrapped — plain `dart:io` `File`
/// copy/delete/exists/read calls stay direct in `DatabaseMaintenanceNotifier`
/// (`settings_providers.dart`), since `dart:io` is pure Dart and already
/// works correctly under `flutter test` on the host, no platform channel
/// involved.
class BackupFileSystem {
  const BackupFileSystem();

  /// Resolves the same application-documents directory `drift_flutter`'s
  /// `driftDatabase(name: 'app_database')` already uses internally to open
  /// `AppDatabase` (`_openConnection()`, `app_database.dart`) — confirmed by
  /// reading its source: no `databasePath`/`databaseDirectory` override is
  /// passed there, so this call independently resolves the exact same path.
  Future<Directory> documentsDirectory() => getApplicationDocumentsDirectory();

  /// Hands the backup file to the OS share sheet (D5: non-destructive, no
  /// confirmation dialog needed — the share sheet is itself the "did you
  /// mean this" moment). `SharePlus.instance.share` — the resolved
  /// `share_plus` 13.3.0 API's current entry point, replacing the older
  /// `Share.shareXFiles` static call.
  Future<void> share(File file) =>
      SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));

  /// Lets the owner pick a file to restore from. `null` means the picker was
  /// cancelled — that is not a refusal (NFR-4), it is simply nothing chosen.
  ///
  /// `FilePicker.pickFile` (not the plural `pickFiles`), the resolved
  /// `file_picker` 12.0.0 API's single-file convenience method — a `static`
  /// call on `FilePicker` itself, not an instance via `.platform`, unlike
  /// older `file_picker` releases.
  Future<File?> pickSqliteFile() async {
    final result = await FilePicker.pickFile();
    final path = result?.path;
    return path == null ? null : File(path);
  }
}
