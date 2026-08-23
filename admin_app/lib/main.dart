import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const WebUpdateAdminApp());
}

const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
const String apiAuthToken = String.fromEnvironment('API_AUTH_TOKEN');

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
    this.imageUrl,
  });

  final String siteName;
  final ContractPlan plan;
  final String info;
  final String? imageUrl;

  factory SiteContent.fromJson(Map<String, dynamic> json) {
    return SiteContent(
      siteName: json['siteName'] as String? ?? '管理サイト',
      plan: ContractPlan.fromApi(json['plan'] as String? ?? 'info'),
      info: json['info'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
    );
  }

  SiteContent copyWith({
    String? siteName,
    ContractPlan? plan,
    String? info,
    String? imageUrl,
  }) {
    return SiteContent(
      siteName: siteName ?? this.siteName,
      plan: plan ?? this.plan,
      info: info ?? this.info,
      imageUrl: imageUrl ?? this.imageUrl,
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

class ContentApi {
  ContentApi({required this.baseUrl, required this.authToken});

  final String baseUrl;
  final String authToken;

  bool get isDemoMode => baseUrl.isEmpty;

  SiteContent _demoContent = const SiteContent(
    siteName: '純喫茶 ロマン',
    plan: ContractPlan.infoImage,
    info: '本日は通常通り営業しています。\n季節限定のプリンセットをご用意しています。',
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

  Future<SiteContent> updateImage(PickedImage image) async {
    if (isDemoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      _demoContent = _demoContent.copyWith(imageUrl: image.name);
      return _demoContent;
    }

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/admin/image'),
    );
    request.headers.addAll(_headers());
    request.files.add(
      http.MultipartFile.fromBytes('image', image.bytes, filename: image.name),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _throwIfFailed(response);
    return SiteContent.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Map<String, String> _headers({String? contentType}) {
    return {'Authorization': 'Bearer $authToken', ?contentType: contentType};
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

class WebUpdateAdminApp extends StatelessWidget {
  const WebUpdateAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'サイト更新',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff5d6f5f),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfffaf8f3),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const AppEntryPoint(),
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  String _authToken = apiAuthToken;

  @override
  Widget build(BuildContext context) {
    if (apiBaseUrl.isNotEmpty && _authToken.isEmpty) {
      return AccessKeyPage(
        onSubmit: (value) {
          setState(() {
            _authToken = value;
          });
        },
      );
    }

    return AdminHomePage(
      api: ContentApi(baseUrl: apiBaseUrl, authToken: _authToken),
      onSignOut: apiBaseUrl.isEmpty
          ? null
          : () {
              setState(() {
                _authToken = '';
              });
            },
    );
  }
}

class AccessKeyPage extends StatefulWidget {
  const AccessKeyPage({required this.onSubmit, super.key});

  final ValueChanged<String> onSubmit;

  @override
  State<AccessKeyPage> createState() => _AccessKeyPageState();
}

class _AccessKeyPageState extends State<AccessKeyPage> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() {
        _errorMessage = '更新キーを入力してください。';
      });
      return;
    }
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('サイト更新')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              children: [
                SectionPanel(
                  title: '更新キー',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _controller,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: '更新キーを入力',
                          errorText: _errorMessage,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.login),
                        label: const Text('開く'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({required this.api, this.onSignOut, super.key});

  final ContentApi api;
  final VoidCallback? onSignOut;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final TextEditingController _infoController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  SiteContent? _content;
  PickedImage? _selectedImage;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _infoController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final content = await widget.api.fetchContent();
      if (!mounted) return;
      setState(() {
        _content = content;
        _infoController.text = content.info;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageFor(error);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedImage = PickedImage(
        name: file.name,
        mimeType: file.mimeType ?? 'image/jpeg',
        bytes: bytes,
      );
    });
  }

  Future<void> _confirmAndSave() async {
    final content = _content;
    if (content == null) return;

    final trimmedInfo = _infoController.text.trim();
    if (trimmedInfo.isEmpty) {
      setState(() => _errorMessage = 'お知らせを入力してください。');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmUpdateDialog(
        siteName: content.siteName,
        info: trimmedInfo,
        image: content.plan.canUpdateImage ? _selectedImage : null,
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      var updated = await widget.api.updateInfo(trimmedInfo);
      if (content.plan.canUpdateImage && _selectedImage != null) {
        updated = await widget.api.updateImage(_selectedImage!);
      }
      if (!mounted) return;
      setState(() {
        _content = updated;
        _infoController.text = updated.info;
        _selectedImage = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('更新しました')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageFor(error);
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _messageFor(Object error) {
    if (error is ContentApiException) {
      return error.message;
    }
    return '通信に失敗しました。詳細: $error';
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;

    return Scaffold(
      appBar: AppBar(
        title: const Text('サイト更新'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: '再読み込み',
            onPressed: _isSaving ? null : _loadContent,
            icon: const Icon(Icons.refresh),
          ),
          if (widget.onSignOut != null)
            IconButton(
              tooltip: '閉じる',
              onPressed: _isSaving ? null : widget.onSignOut,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : content == null
            ? ErrorView(
                message: _errorMessage ?? '内容を取得できませんでした。',
                onRetry: _loadContent,
              )
            : ListView(
                key: const ValueKey('admin-content-list'),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  HeaderPanel(
                    content: content,
                    isDemoMode: widget.api.isDemoMode,
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    ErrorBanner(message: _errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  SectionPanel(
                    title: 'お知らせ',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _infoController,
                          minLines: 6,
                          maxLines: 10,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'お知らせ内容を入力',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (content.plan.canUpdateImage) ...[
                    const SizedBox(height: 16),
                    SectionPanel(
                      title: '画像',
                      child: ImageUpdateField(
                        currentImageUrl: content.imageUrl,
                        selectedImage: _selectedImage,
                        onPickImage: _pickImage,
                        onClearImage: _selectedImage == null
                            ? null
                            : () => setState(() => _selectedImage = null),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _confirmAndSave,
                    icon: _isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isSaving ? '更新中' : '内容を確認して更新'),
                  ),
                ],
              ),
      ),
    );
  }
}

class HeaderPanel extends StatelessWidget {
  const HeaderPanel({
    required this.content,
    required this.isDemoMode,
    super.key,
  });

  final SiteContent content;
  final bool isDemoMode;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: content.siteName,
      child: Row(
        children: [
          Icon(
            content.plan.canUpdateImage
                ? Icons.image_outlined
                : Icons.article_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content.plan.canUpdateImage ? 'お知らせと画像を更新できます' : 'お知らせを更新できます',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (isDemoMode)
            const Chip(label: Text('デモ'), visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}

class SectionPanel extends StatelessWidget {
  const SectionPanel({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffe4ded3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class ImageUpdateField extends StatelessWidget {
  const ImageUpdateField({
    required this.currentImageUrl,
    required this.selectedImage,
    required this.onPickImage,
    required this.onClearImage,
    super.key,
  });

  final String? currentImageUrl;
  final PickedImage? selectedImage;
  final VoidCallback onPickImage;
  final VoidCallback? onClearImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xfff1eee8)),
              child: selectedImage != null
                  ? Image.memory(selectedImage!.bytes, fit: BoxFit.cover)
                  : currentImageUrl == null
                  ? const Center(child: Text('現在の画像はありません'))
                  : Image.network(
                      currentImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Text('画像を表示できません'));
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('画像を選択'),
              ),
            ),
            if (onClearImage != null) ...[
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: '選択を取り消す',
                onPressed: onClearImage,
                icon: const Icon(Icons.close),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class ConfirmUpdateDialog extends StatelessWidget {
  const ConfirmUpdateDialog({
    required this.siteName,
    required this.info,
    required this.image,
    super.key,
  });

  final String siteName;
  final String info;
  final PickedImage? image;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('更新内容の確認'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(siteName, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            const Text('お知らせ'),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xfff7f4ee),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(info),
              ),
            ),
            if (image != null) ...[
              const SizedBox(height: 12),
              const Text('新しい画像'),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  image!.bytes,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('戻る'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('更新する'),
        ),
      ],
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfffff0ed),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffffc7bd)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ErrorMessageContent(message: message),
      ),
    );
  }
}

class ErrorMessageContent extends StatelessWidget {
  const ErrorMessageContent({required this.message, super.key});

  final String message;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: message));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('コピーしました')));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, color: Color(0xffb3261e)),
        const SizedBox(width: 8),
        Expanded(child: SelectableText(message)),
        const SizedBox(width: 8),
        IconButton.outlined(
          tooltip: 'コピー',
          onPressed: () => _copy(context),
          icon: const Icon(Icons.copy),
        ),
      ],
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xfffff0ed),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xffffc7bd)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ErrorMessageContent(message: message),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }
}
