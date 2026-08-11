import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../services/backup/restore_durability.dart';
import 'app_database.dart';
import 'database_installation_gate.dart';

/// User-initiated recovery actions for the pre-initialization failure screen.
///
/// These run before any app services exist, so every operation works purely at
/// the file level. They exist to guarantee that a fail-closed startup can never
/// become a permanent lockout: the user can always salvage a copy of their
/// data, repair recoverable metadata damage, or (as a last resort) reset.
final class StartupRecoveryService {
  StartupRecoveryService._();

  // Inert OS metadata files that must never block startup validation.
  static const _junkFileNames = <String>{
    '.DS_Store',
    'Thumbs.db',
    'desktop.ini',
    '.localized',
  };

  static const _receiptPrefix = 'database_installation_receipt_';
  static const _receiptSuffix = '.json';
  static const _temporaryPrefix = '.database_installation_receipt';
  static const _temporarySuffix = '.tmp';
  static const _restoreWorkspaceName = '.kelivo_restore';

  /// Copies the entire app data directory into a timestamped folder under
  /// [destinationParent] so the user can salvage their data before attempting
  /// any repair or reset. Returns the created directory. Non-destructive.
  static Future<Directory> exportDataCopy({
    required Directory appDataDirectory,
    required Directory destinationParent,
    DateTime Function()? clock,
  }) async {
    if (!await appDataDirectory.exists()) {
      throw StateError('startup_recovery_source_missing');
    }
    // A destination inside the data directory would make the copy recurse
    // into itself (the target shows up while the source is being listed).
    final sourcePath = p.normalize(appDataDirectory.absolute.path);
    final destinationPath = p.normalize(destinationParent.absolute.path);
    if (destinationPath == sourcePath ||
        p.isWithin(sourcePath, destinationPath)) {
      throw StateError('startup_recovery_export_inside_source');
    }
    await destinationParent.create(recursive: true);
    final stamp = (clock?.call() ?? DateTime.now())
        .toUtc()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-');
    final target = Directory(
      p.join(destinationParent.path, 'kelivo-data-$stamp'),
    );
    if (await target.exists()) {
      throw StateError('startup_recovery_export_collision');
    }
    await target.create(recursive: true);
    await _copyDirectory(appDataDirectory, target);
    return target;
  }

  /// Repairs recoverable metadata damage that fails startup closed without any
  /// real data loss: leftover publish temp files, inert OS junk inside the
  /// restore workspace, and unparseable installation receipts. It then
  /// re-runs admission, adopting the current database's identity so a corrupt
  /// or swapped receipt is rewritten from the authoritative on-disk database.
  ///
  /// Rethrows when the database itself is missing or corrupt: those cannot be
  /// repaired at the file level and the caller should offer a reset instead.
  static Future<void> repair({
    required Directory appDataDirectory,
    RestoreDurability? durability,
  }) async {
    if (!await appDataDirectory.exists()) {
      throw StateError('startup_recovery_source_missing');
    }
    await _sweepReceiptTemporaries(appDataDirectory);
    await _sweepRestoreWorkspaceJunk(appDataDirectory);
    await _deleteUnparseableReceipts(appDataDirectory);
    // Adopting the identity lets a receipt that was deleted (because it was
    // unparseable) or that mismatches be rewritten from the live database. A
    // user electing to repair is implicitly trusting the database on disk.
    await DatabaseInstallationGate.ensureReady(
      appDataDirectory: appDataDirectory,
      allowDatabaseIdentityChange: true,
      durability: durability,
    );
  }

  /// Deletes the installed database family and installation receipts and
  /// re-runs first-launch setup. Destructive: the current database is lost.
  /// Callers must confirm with the user and should offer [exportDataCopy]
  /// first.
  static Future<void> reset({
    required Directory appDataDirectory,
    RestoreDurability? durability,
  }) async {
    // Remove installation receipts (and any temps) first: rebuildFresh only
    // recreates the database family, and admission rejects a receipt whose
    // database has been rebuilt. Clearing them lets a fresh identity issue
    // cleanly.
    await _sweepReceiptTemporaries(appDataDirectory);
    await for (final entity in appDataDirectory.list(followLinks: false)) {
      final name = p.basename(entity.path);
      if (name.startsWith(_receiptPrefix) && name.endsWith(_receiptSuffix)) {
        await _deleteFileIfPresent(entity.path);
      }
    }
    await DatabaseInstallationGate.rebuildFresh(
      appDataDirectory: appDataDirectory,
      durability: durability,
    );
  }

  static Future<void> _copyDirectory(Directory source, Directory target) async {
    await for (final entity in source.list(followLinks: false)) {
      final name = p.basename(entity.path);
      final destinationPath = p.join(target.path, name);
      if (entity is Directory) {
        final childTarget = Directory(destinationPath);
        await childTarget.create(recursive: true);
        await _copyDirectory(entity, childTarget);
      } else if (entity is File) {
        await entity.copy(destinationPath);
      }
      // Links and other special entities are intentionally skipped.
    }
  }

  static Future<void> _sweepReceiptTemporaries(Directory directory) async {
    await for (final entity in directory.list(followLinks: false)) {
      final name = p.basename(entity.path);
      if (name.startsWith(_temporaryPrefix) &&
          name.endsWith(_temporarySuffix)) {
        await _deleteFileIfPresent(entity.path);
      }
    }
  }

  static Future<void> _sweepRestoreWorkspaceJunk(Directory directory) async {
    final workspace = Directory(p.join(directory.path, _restoreWorkspaceName));
    if (!await workspace.exists()) return;
    await for (final entity in workspace.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && _junkFileNames.contains(p.basename(entity.path))) {
        await _deleteFileIfPresent(entity.path);
      }
    }
  }

  static Future<void> _deleteUnparseableReceipts(Directory directory) async {
    await for (final entity in directory.list(followLinks: false)) {
      final name = p.basename(entity.path);
      if (!name.startsWith(_receiptPrefix) || !name.endsWith(_receiptSuffix)) {
        continue;
      }
      if (await FileSystemEntity.type(entity.path, followLinks: false) !=
          FileSystemEntityType.file) {
        continue;
      }
      final file = File(entity.path);
      var valid = false;
      try {
        DatabaseInstallationReceipt.fromJson(
          jsonDecode(await file.readAsString()),
        );
        valid = true;
      } catch (_) {
        valid = false;
      }
      if (!valid) {
        await _deleteFileIfPresent(entity.path);
      }
    }
  }

  static Future<void> _deleteFileIfPresent(String path) async {
    try {
      if (await FileSystemEntity.type(path, followLinks: false) ==
          FileSystemEntityType.file) {
        await File(path).delete();
      }
    } catch (_) {
      // Best-effort: an undeletable junk/temp file does not block admission,
      // which uses unique temp names and adopts the database identity.
    }
  }

  /// The installed database file name, exposed so the failure screen can note
  /// what a reset will remove.
  static String get databaseFileName => AppDatabase.databaseFileName;
}
