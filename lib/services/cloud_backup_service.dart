import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();
  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

/// Stores a single backup JSON file in the signed-in user's Google Drive
/// "app data" folder — a hidden, per-app storage area that only this app
/// can see or modify (the user's other Drive files/folders are never
/// touched, and the file doesn't count against their visible Drive
/// storage view).
class CloudBackupService {
  static const _backupFileName = 'daftar_al_hisab_backup.json';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (_) {
      return null;
    }
  }

  /// Tries to restore a previous Google session without showing any UI.
  /// Safe to call on every app start.
  static Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (_) {
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore
    }
  }

  static Future<drive.DriveApi?> _driveApi() async {
    final account = _googleSignIn.currentUser ?? await signInSilently();
    if (account == null) return null;
    final headers = await account.authHeaders;
    return drive.DriveApi(_GoogleAuthClient(headers));
  }

  static Future<drive.File?> _findBackupFile(drive.DriveApi api) async {
    final result = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName' and trashed = false",
      $fields: 'files(id, name, modifiedTime)',
    );
    if (result.files == null || result.files!.isEmpty) return null;
    return result.files!.first;
  }

  /// Uploads (or overwrites) the single backup file in the user's Drive
  /// app-data folder.
  static Future<void> uploadBackup(Map<String, dynamic> data) async {
    final api = await _driveApi();
    if (api == null) throw Exception('not_signed_in');

    final bytes = utf8.encode(jsonEncode(data));
    final media = drive.Media(Stream.value(bytes), bytes.length);
    final existing = await _findBackupFile(api);

    if (existing != null) {
      await api.files.update(drive.File(), existing.id!, uploadMedia: media);
    } else {
      final file = drive.File()
        ..name = _backupFileName
        ..parents = ['appDataFolder'];
      await api.files.create(file, uploadMedia: media);
    }
  }

  /// Downloads and parses the backup file, or returns null if the signed
  /// in account has no backup yet (or isn't signed in at all).
  static Future<Map<String, dynamic>?> downloadBackup() async {
    final api = await _driveApi();
    if (api == null) return null;

    final existing = await _findBackupFile(api);
    if (existing == null) return null;

    final media = await api.files.get(
      existing.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  static Future<DateTime?> lastBackupTime() async {
    final api = await _driveApi();
    if (api == null) return null;
    final existing = await _findBackupFile(api);
    return existing?.modifiedTime;
  }
}
