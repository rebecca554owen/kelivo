import 'dart:typed_data';

import 'package:downsize/downsize.dart';
import 'package:image/image.dart';

/// Config class holds raw data with compression options.
class Config {
  /// initial image data.
  final Uint8List data;

  /// minimum image quality.
  final int minQuality;

  /// desired file size.
  final double? maxSize;

  Config({required this.data, this.minQuality = 60, this.maxSize});
}

class Downsize {
  static Future<Uint8List?> downsize({
    required Uint8List data,
    int minQuality = 60,
    double? maxSize,
  }) async {
    if (data.isEmpty) return data;
    return Downsize().compress(Config(
      data: data,
      minQuality: minQuality,
      maxSize: maxSize,
    ));
  }

  /// Decode and Compress image data.
  Uint8List? compress(Config config) {
    Image? image = decodeImage(config.data);
    if (image == null) {
      throw Exception("Unsupported image type.");
    }

    bool isJpg = JpegDecoder().isValidFile(config.data);
    bool isPng = isJpg ? false : PngDecoder().isValidFile(config.data);

    if (!isPng && !isJpg) {
      Uint8List data = encodeJpg(image);
      image = decodeImage(data);
      if (image == null) {
        throw Exception("Unsupported image type.");
      }
      isJpg = true;
    }

    var fileSize = config.data.sizeKb;
    // print('Old File Size Is: ${fileSize}kb, desired size: ${config.maxSize}kb');
    if (config.maxSize != null && fileSize <= config.maxSize!) {
      return config.data;
    }

    // print("image dimensions: ${image.width}/${image.height}");

    if (isPng) {
      // print('compressPng()');
      return compressPng(image: image, config: config);
    }
    // print('compressJpg()');
    return compressJpg(image: image, config: config);
  }

  /// Compress JPG image.
  Uint8List compressJpg({
    required Image image,
    required Config config,
    int quality = 90,
    bool preTreatment = true,
  }) {
    if (preTreatment) {
      image = dynamicResize(image);
      // print("resized to dimensions: ${image.width}/${image.height}");
    }

    final im = encodeJpg(image, quality: quality);
    if (config.maxSize != null &&
        im.sizeKb > config.maxSize! &&
        (quality - 10) >= config.minQuality) {
      // print('quality => ${quality - 10}');
      return compressJpg(
        image: image,
        config: config,
        quality: quality - 10,
        preTreatment: false,
      );
    }

    return im;
  }

  /// Compress PNG image.
  Uint8List compressPng({
    required Image image,
    required Config config,
    int level = 9,
  }) {
    int width = image.width;
    int height = image.height;

    image = dynamicResize(image);
    // print("resized to dimensions: ${image.width}/${image.height}");

    // remove transparency
    image = copyResize(
      image,
      backgroundColor: ColorRgb8(255, 255, 255),
      width: width,
      height: height,
    );

    // downsize the number of colors (to 8-bit)
    image = quantize(image, numberOfColors: 256);

    var im = encodePng(image, level: level, filter: PngFilter.none);

    return im;
  }

  /// Dynamically resize the image based on its dimensions.
  Image dynamicResize(Image image) {
    bool byWidth = image.width > image.height;
    int originalSize = byWidth ? image.width : image.height;
    int size = originalSize;

    if (originalSize > 2000) {
      size = (originalSize * 0.5).round();
    } else if (originalSize > 1000) {
      size = (originalSize * 0.75).round();
    } else if (originalSize > 500) {
      size = (originalSize * 0.9).round();
    } else {
      return image;
    }

    return copyResize(
      image,
      width: byWidth ? size : null,
      height: byWidth ? null : size,
    );
  }
}
