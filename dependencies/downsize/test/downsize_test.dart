import 'dart:io';
import 'dart:typed_data';

import 'package:downsize/downsize.dart';
import 'package:test/test.dart';

void main() {
  group('Downsize Image', () {
    Uint8List? data =
        File('${Directory.current.path}/example/test.png').readAsBytesSync();
    print('Old size: ${data.sizeKb}kb');

    setUp(() {
      // Additional setup goes here.
    });

    test('Reducing size Test', () async {
      double? newSize = (await Downsize.downsize(data: data))?.sizeKb;
      print('New size: ${newSize}kb');
      expect(data.sizeKb, greaterThanOrEqualTo(newSize!));
    });
  });
}
