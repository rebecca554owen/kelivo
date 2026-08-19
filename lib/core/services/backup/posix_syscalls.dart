import 'dart:ffi';
import 'dart:io';

/// POSIX `open` flags and libc symbol names shared by the restore internals
/// that talk to libc directly.
///
/// The values are architecture-specific: Android ARM does not use the
/// asm-generic numbering, and Apple platforms differ again.
final class PosixSyscalls {
  const PosixSyscalls._();

  static final bool _isApple = Platform.isMacOS || Platform.isIOS;

  // Android ARM uses architecture-specific O_DIRECTORY/O_NOFOLLOW values.
  static bool get _usesAndroidArmOpenFlags {
    final abi = Abi.current();
    return abi == Abi.androidArm || abi == Abi.androidArm64;
  }

  static const int oReadWrite = 2;

  static int get oDirectory => _isApple
      ? 0x00100000
      : _usesAndroidArmOpenFlags
      ? 0x00004000
      : 0x00010000;

  static int get oNoFollow => _isApple
      ? 0x00000100
      : _usesAndroidArmOpenFlags
      ? 0x00008000
      : 0x00020000;

  static int get oCloseOnExec => _isApple ? 0x01000000 : 0x00080000;

  static const int eintr = 4;

  static int get eagain => _isApple ? 35 : 11;

  static String get errnoSymbol => Platform.isAndroid
      ? '__errno'
      : _isApple
      ? '__error'
      : '__errno_location';
}
