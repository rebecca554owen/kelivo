import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:Kelivo/core/services/backup/restore_lease_lock.dart';

void main() {
  group('RestoreLeaseLock', () {
    late Directory root;
    late File lockFile;

    setUp(() async {
      root = await Directory.systemTemp.createTemp(
        'kelivo_restore_lease_lock_test_',
      );
      lockFile = File(p.join(root.path, 'lease.lock'));
      await lockFile.create();
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('excludes a second descriptor inside this process', () async {
      final held = await RestoreLeaseLock.tryAcquire(lockFile);
      expect(held, isNotNull);
      addTearDown(held!.release);

      expect(await RestoreLeaseLock.tryAcquire(lockFile), isNull);

      await held.release();
      final reacquired = await RestoreLeaseLock.tryAcquire(lockFile);
      expect(reacquired, isNotNull);
      await reacquired!.release();
    });

    test('survives an unrelated descriptor closing in this process', () async {
      final held = await RestoreLeaseLock.tryAcquire(lockFile);
      expect(held, isNotNull);
      addTearDown(held!.release);

      // A POSIX record lock would be dropped here, because closing any
      // descriptor of the file releases every record lock the process holds.
      final unrelated = await lockFile.open(mode: FileMode.append);
      await unrelated.close();

      expect(await RestoreLeaseLock.tryAcquire(lockFile), isNull);
    });

    test('release is idempotent', () async {
      final held = await RestoreLeaseLock.tryAcquire(lockFile);
      expect(held, isNotNull);
      await held!.release();
      await held.release();

      final reacquired = await RestoreLeaseLock.tryAcquire(lockFile);
      expect(reacquired, isNotNull);
      await reacquired!.release();
    });

    test(
      'binds the description-scoped lock on this platform',
      () async {
        final held = await RestoreLeaseLock.tryAcquire(lockFile);
        expect(held, isNotNull);
        addTearDown(held!.release);
        expect(held.isDescriptionScoped, isTrue);
      },
      skip: Platform.isWindows
          ? 'Windows handle locks use the dart:io path.'
          : false,
    );
  });
}
