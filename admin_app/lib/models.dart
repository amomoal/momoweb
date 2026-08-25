import 'dart:typed_data';

enum ContractPlan {
  info,
  infoImage;

  bool get canUpdateImage => this == ContractPlan.infoImage;

  static ContractPlan fromApi(String value) {
    return value == 'info_image' ? ContractPlan.infoImage : ContractPlan.info;
  }
}

class SiteContent {
  const SiteContent({
    required this.siteName,
    required this.plan,
    required this.info,
    required this.imagePositionX,
    required this.imagePositionY,
    required this.imageAspectWidth,
    required this.imageAspectHeight,
    required this.imageCropScale,
    required this.imageCropOffsetX,
    required this.imageCropOffsetY,
    this.imageUrl,
  });

  final String siteName;
  final ContractPlan plan;
  final String info;
  final double imagePositionX;
  final double imagePositionY;
  final int imageAspectWidth;
  final int imageAspectHeight;
  final double imageCropScale;
  final double imageCropOffsetX;
  final double imageCropOffsetY;
  final String? imageUrl;

  double get imageAspectRatio => imageAspectWidth / imageAspectHeight;

  factory SiteContent.fromJson(Map<String, dynamic> json) {
    return SiteContent(
      siteName: json['siteName'] as String? ?? '管理サイト',
      plan: ContractPlan.fromApi(json['plan'] as String? ?? 'info'),
      info: json['info'] as String? ?? '',
      imagePositionX: _positionFromJson(json['imagePositionX']),
      imagePositionY: _positionFromJson(json['imagePositionY']),
      imageAspectWidth: _aspectPartFromJson(json['imageAspectWidth'], 16),
      imageAspectHeight: _aspectPartFromJson(json['imageAspectHeight'], 9),
      imageCropScale: _scaleFromJson(json['imageCropScale']),
      imageCropOffsetX: _offsetFromJson(json['imageCropOffsetX']),
      imageCropOffsetY: _offsetFromJson(json['imageCropOffsetY']),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  SiteContent copyWith({
    String? siteName,
    ContractPlan? plan,
    String? info,
    double? imagePositionX,
    double? imagePositionY,
    int? imageAspectWidth,
    int? imageAspectHeight,
    double? imageCropScale,
    double? imageCropOffsetX,
    double? imageCropOffsetY,
    String? imageUrl,
  }) {
    return SiteContent(
      siteName: siteName ?? this.siteName,
      plan: plan ?? this.plan,
      info: info ?? this.info,
      imagePositionX: imagePositionX ?? this.imagePositionX,
      imagePositionY: imagePositionY ?? this.imagePositionY,
      imageAspectWidth: imageAspectWidth ?? this.imageAspectWidth,
      imageAspectHeight: imageAspectHeight ?? this.imageAspectHeight,
      imageCropScale: imageCropScale ?? this.imageCropScale,
      imageCropOffsetX: imageCropOffsetX ?? this.imageCropOffsetX,
      imageCropOffsetY: imageCropOffsetY ?? this.imageCropOffsetY,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static double _positionFromJson(Object? value) {
    if (value is num) {
      return value.clamp(0, 100).toDouble();
    }
    return 50;
  }

  static int _aspectPartFromJson(Object? value, int fallback) {
    if (value is num && value > 0) {
      return value.clamp(1, 100).round();
    }
    return fallback;
  }

  static double _scaleFromJson(Object? value) {
    if (value is num) {
      return value.clamp(1, 4).toDouble();
    }
    return 1;
  }

  static double _offsetFromJson(Object? value) {
    if (value is num) {
      return value.clamp(-150, 150).toDouble();
    }
    return 0;
  }
}

class ImageCrop {
  const ImageCrop({
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  const ImageCrop.initial() : scale = 1, offsetX = 0, offsetY = 0;

  final double scale;
  final double offsetX;
  final double offsetY;

  ImageCrop copyWith({double? scale, double? offsetX, double? offsetY}) {
    return ImageCrop(
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
    );
  }
}

class PickedImage {
  const PickedImage({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;
}
