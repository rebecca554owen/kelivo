import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'posix_syscalls.dart';

/// A non-blocking exclusive advisory lock on a fixed lease file.
///
/// POSIX record locks, which `RandomAccessFile.lock` uses, are owned by the
/// process: closing any descriptor of the file releases every record lock the
/// process holds on it, and a second descriptor may re-take a lock the process
/// already owns. Android recreates the Flutter engine, and with it a second
/// root isolate, inside a surviving process, so both properties are reachable
/// in production and neither is acceptable for a business-data lease.
///
/// `flock` is bound to the open file description instead. The outgoing
/// engine's descriptor closing therefore cannot release the incoming engine's
/// lock, and two descriptors in one process contend exactly like two
/// processes. Windows handle locks already have that shape; the record-lock
/// fallback stays reachable if the libc symbols cannot be bound.
final class RestoreLeaseLock {
  RestoreLeaseLock._flock(this._libc, this._descriptor) : _handle = null;
  RestoreLeaseLock._recordLock(this._handle) : _libc = null, _descriptor = null;

  final _Libc? _libc;
  final int? _descriptor;
  final RandomAccessFile? _handle;
  var _released = false;

  /// Whether this lock is scoped to the open file description.
  ///
  /// False means the process-wide record-lock fallback is in use, where
  /// another descriptor closing in this process can drop the lock.
  bool get isDescriptionScoped => _descriptor != null;

  /// Takes the lock without waiting.
  ///
  /// Returns null when the lock is held by another descriptor, in this process
  /// or any other. Every other failure is reported as a [FileSystemException].
  static Future<RestoreLeaseLock?> tryAcquire(File file) async {
    final libc = _Libc.instance;
    if (libc != null) return libc.tryAcquire(file);
    return _tryAcquireRecordLock(file);
  }

  /// Releases the lock. Repeated calls are harmless.
  Future<void> release() async {
    if (_released) return;
    _released = true;
    final descriptor = _descriptor;
    if (descriptor != null) {
      _libc!.release(descriptor);
      return;
    }
    final handle = _handle!;
    try {
      await handle.unlock();
    } finally {
      await handle.close();
    }
  }

  static Future<RestoreLeaseLock?> _tryAcquireRecordLock(File file) async {
    final handle = await file.open(mode: FileMode.append);
    try {
      await handle.lock(FileLock.exclusive);
    } on FileSystemException catch (error) {
      await handle.close();
      if (_isRecordLockUnavailable(error)) return null;
      rethrow;
    } catch (_) {
      await handle.close();
      rethrow;
    }
    return RestoreLeaseLock._recordLock(handle);
  }

  static bool _isRecordLockUnavailable(FileSystemException error) {
    final code = error.osError?.errorCode;
    if (code == null) return false;
    if (Platform.isWindows) return code == 32 || code == 33;
    return code == 11 || code == 13 || code == 35;
  }
}

typedef _OpenNative = Int32 Function(Pointer<Utf8>, Int32);
typedef _OpenDart = int Function(Pointer<Utf8>, int);
typedef _FlockNative = Int32 Function(Int32, Int32);
typedef _FlockDart = int Function(int, int);
typedef _CloseNative = Int32 Function(Int32);
typedef _CloseDart = int Function(int);
typedef _ErrnoNative = Pointer<Int32> Function();
typedef _ErrnoDart = Pointer<Int32> Function();

/// The libc entry points backing description-scoped locking.
final class _Libc {
  _Libc._(this._open, this._flock, this._close, this._errnoLocation);

  // `open` is variadic in C, but its mode argument only exists together with
  // O_CREAT. The lease file is created through dart:io first, so this call
  // passes no variadic argument and matches the fixed-argument convention on
  // every supported ABI.
  final _OpenDart _open;
  final _FlockDart _flock;
  final _CloseDart _close;
  final _ErrnoDart _errnoLocation;

  static const _lockExclusive = 2;
  static const _lockNonBlocking = 4;
  static const _lockUnlock = 8;

  static final _Libc? instance = _bind();

  static _Libc? _bind() {
    if (!Platform.isAndroid &&
        !Platform.isIOS &&
        !Platform.isMacOS &&
        !Platform.isLinux) {
      return null;
    }
    try {
      final process = DynamicLibrary.process();
      return _Libc._(
        process.lookupFunction<_OpenNative, _OpenDart>('open'),
        process.lookupFunction<_FlockNative, _FlockDart>('flock'),
        process.lookupFunction<_CloseNative, _CloseDart>('close'),
        process.lookupFunction<_ErrnoNative, _ErrnoDart>(
          PosixSyscalls.errnoSymbol,
        ),
      );
    } catch (_) {
      // A platform that will not bind these symbols keeps the record-lock
      // fallback rather than failing startup.
      return null;
    }
  }

  int get _errno => _errnoLocation().value;

  Future<RestoreLeaseLock?> tryAcquire(File file) async {
    final nativePath = file.absolute.path.toNativeUtf8();
    var descriptor = -1;
    try {
      while (true) {
        descriptor = _open(
          nativePath,
          PosixSyscalls.oReadWrite |
              PosixSyscalls.oNoFollow |
              PosixSyscalls.oCloseOnExec,
        );
        if (descriptor >= 0) break;
        final errno = _errno;
        if (errno == PosixSyscalls.eintr) continue;
        throw FileSystemException(
          'restore_lease_lock_open',
          file.path,
          OSError('open failed', errno),
        );
      }
    } finally {
      malloc.free(nativePath);
    }
    while (true) {
      if (_flock(descriptor, _lockExclusive | _lockNonBlocking) == 0) {
        return RestoreLeaseLock._flock(this, descriptor);
      }
      final errno = _errno;
      if (errno == PosixSyscalls.eintr) continue;
      _close(descriptor);
      if (errno == PosixSyscalls.eagain) return null;
      throw FileSystemException(
        'restore_lease_lock_flock',
        file.path,
        OSError('flock failed', errno),
      );
    }
  }

  void release(int descriptor) {
    _flock(descriptor, _lockUnlock);
    _close(descriptor);
  }
}
