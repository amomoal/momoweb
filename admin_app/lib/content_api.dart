import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'models.dart';

class ContentApi {
  ContentApi({required this.baseUrl, required this.authToken});

  final String baseUrl;
  final String authToken;

  bool get isDemoMode => baseUrl.isEmpty;

  SiteContent _demoContent = const SiteContent(
    siteName: '純喫茶 ロマン',
    plan: ContractPlan.infoImage,
    info: '本日は通常通り営業しています。\n季節限定のプリンセットをご用意しています。',
    imagePositionX: 50,
    imagePositionY: 50,
    imageAspectWidth: 16,
    imageAspectHeight: 9,
    imageCropScale: 1,
    imageCropOffsetX: 0,
    imageCropOffsetY: 0,
    imageUrl: null,
  );

  Future<SiteContent> fetchContent() async {
    if (isDemoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return _demoContent;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/admin/content'),
      headers: _headers(),
    );
    _throwIfFailed(response);
    return SiteContent.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<SiteContent> updateInfo(String info) async {
    if (isDemoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      _demoContent = _demoContent.copyWith(info: info);
      return _demoContent;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/admin/info'),
      headers: _headers(contentType: 'application/json'),
      body: jsonEncode({'info': info}),
    );
    _throwIfFailed(response);
    return SiteContent.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<SiteContent> updateImage(
    PickedImage image, {
    required ImageCrop crop,
  }) async {
    if (isDemoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      _demoContent = _demoContent.copyWith(
        imageUrl: image.name,
        imagePositionX: 50,
        imagePositionY: 50,
        imageCropScale: crop.scale,
        imageCropOffsetX: crop.offsetX,
        imageCropOffsetY: crop.offsetY,
      );
      return _demoContent;
    }

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/admin/image'),
    );
    request.headers.addAll(_headers());
    request.fields['imageCropScale'] = crop.scale.toStringAsFixed(3);
    request.fields['imageCropOffsetX'] = crop.offsetX.toStringAsFixed(3);
    request.fields['imageCropOffsetY'] = crop.offsetY.toStringAsFixed(3);
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        image.bytes,
        filename: image.name,
        contentType: MediaType.parse(image.mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _throwIfFailed(response);
    return SiteContent.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<SiteContent> updateImageCrop({required ImageCrop crop}) async {
    if (isDemoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      _demoContent = _demoContent.copyWith(
        imageCropScale: crop.scale,
        imageCropOffsetX: crop.offsetX,
        imageCropOffsetY: crop.offsetY,
      );
      return _demoContent;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/admin/image-position'),
      headers: _headers(contentType: 'application/json'),
      body: jsonEncode({
        'imageCropScale': crop.scale,
        'imageCropOffsetX': crop.offsetX,
        'imageCropOffsetY': crop.offsetY,
      }),
    );
    _throwIfFailed(response);
    return SiteContent.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Map<String, String> _headers({String? contentType}) {
    final headers = {'Authorization': 'Bearer $authToken'};
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }
    return headers;
  }

  void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    var message = '更新できませんでした。時間をおいて再度お試しください。';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['message'] as String? ?? message;
    } catch (_) {
      // Keep the user-facing fallback.
    }
    throw ContentApiException(message);
  }
}

class ContentApiException implements Exception {
  ContentApiException(this.message);

  final String message;
}
