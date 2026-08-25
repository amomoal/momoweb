import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'auth_token_store.dart';
import 'content_api.dart';
import 'models.dart';
import 'widgets.dart';

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({
    required this.apiBaseUrl,
    required this.initialAuthToken,
    required this.authTokenStore,
    required this.publicSiteUrl,
    super.key,
  });

  final String apiBaseUrl;
  final String initialAuthToken;
  final AuthTokenStore authTokenStore;
  final String publicSiteUrl;

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  late String _authToken = widget.initialAuthToken;
  bool _shouldRememberAuthToken = true;
  bool _isLoadingToken = false;

  @override
  void initState() {
    super.initState();
    if (widget.apiBaseUrl.isNotEmpty && _authToken.isEmpty) {
      _loadSavedToken();
    }
  }

  Future<void> _loadSavedToken() async {
    setState(() => _isLoadingToken = true);
    final savedToken = await widget.authTokenStore.read();
    if (!mounted) return;
    setState(() {
      _authToken = savedToken;
      _isLoadingToken = false;
    });
  }

  Future<void> _saveAuthToken(String token) async {
    if (widget.apiBaseUrl.isEmpty || token.isEmpty) return;
    if (_shouldRememberAuthToken) {
      await widget.authTokenStore.save(token);
    } else {
      await widget.authTokenStore.clear();
    }
  }

  Future<void> _clearAuthToken() async {
    await widget.authTokenStore.clear();
    if (!mounted) return;
    setState(() {
      _authToken = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingToken) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (widget.apiBaseUrl.isNotEmpty && _authToken.isEmpty) {
      return AccessKeyPage(
        onSubmit: (submission) {
          setState(() {
            _authToken = submission.token;
            _shouldRememberAuthToken = submission.shouldRemember;
          });
        },
      );
    }

    return AdminHomePage(
      api: ContentApi(baseUrl: widget.apiBaseUrl, authToken: _authToken),
      onAuthAccepted: _saveAuthToken,
      publicSiteUrl: widget.publicSiteUrl,
      onSignOut: widget.apiBaseUrl.isEmpty
          ? null
          : () {
              _clearAuthToken();
            },
    );
  }
}

class AccessKeyPage extends StatefulWidget {
  const AccessKeyPage({required this.onSubmit, super.key});

  final ValueChanged<AccessKeySubmission> onSubmit;

  @override
  State<AccessKeyPage> createState() => _AccessKeyPageState();
}

class _AccessKeyPageState extends State<AccessKeyPage> {
  final TextEditingController _controller = TextEditingController();
  bool _shouldRemember = true;
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
    widget.onSubmit(
      AccessKeySubmission(token: value, shouldRemember: _shouldRemember),
    );
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
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _shouldRemember,
                        onChanged: (value) {
                          setState(() {
                            _shouldRemember = value ?? true;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('入力内容を次回も表示'),
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

class AccessKeySubmission {
  const AccessKeySubmission({
    required this.token,
    required this.shouldRemember,
  });

  final String token;
  final bool shouldRemember;
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({
    required this.api,
    required this.publicSiteUrl,
    this.onAuthAccepted,
    this.onSignOut,
    super.key,
  });

  final ContentApi api;
  final String publicSiteUrl;
  final ValueChanged<String>? onAuthAccepted;
  final VoidCallback? onSignOut;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final TextEditingController _infoController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  SiteContent? _content;
  PickedImage? _selectedImage;
  ImageCrop _imageCrop = const ImageCrop.initial();
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
        _imageCrop = ImageCrop(
          scale: content.imageCropScale,
          offsetX: content.imageCropOffsetX,
          offsetY: content.imageCropOffsetY,
        );
      });
      widget.onAuthAccepted?.call(widget.api.authToken);
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
    _dismissKeyboard();
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
      _imageCrop = const ImageCrop.initial();
    });
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
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
        imageAspectRatio: content.plan.canUpdateImage
            ? content.imageAspectRatio
            : null,
        imageCrop: content.plan.canUpdateImage ? _imageCrop : null,
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
        updated = await widget.api.updateImage(
          _selectedImage!,
          crop: _imageCrop,
        );
      } else if (content.plan.canUpdateImage) {
        updated = await widget.api.updateImageCrop(crop: _imageCrop);
      }
      if (!mounted) return;
      setState(() {
        _content = updated;
        _infoController.text = updated.info;
        _imageCrop = ImageCrop(
          scale: updated.imageCropScale,
          offsetX: updated.imageCropOffsetX,
          offsetY: updated.imageCropOffsetY,
        );
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
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissKeyboard,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : content == null
              ? ErrorView(
                  message: _errorMessage ?? '内容を取得できませんでした。',
                  onRetry: _loadContent,
                )
              : ListView(
                  key: const ValueKey('admin-content-list'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    HeaderPanel(
                      content: content,
                      isDemoMode: widget.api.isDemoMode,
                      publicSiteUrl: widget.publicSiteUrl,
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null) ...[
                      ErrorBanner(message: _errorMessage!),
                      const SizedBox(height: 16),
                    ],
                    SectionPanel(
                      title: 'お知らせ',
                      child: TextField(
                        controller: _infoController,
                        minLines: 6,
                        maxLines: 10,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: _dismissKeyboard,
                        onTapOutside: (_) => _dismissKeyboard(),
                        decoration: const InputDecoration(
                          hintText: 'お知らせ内容を入力',
                        ),
                      ),
                    ),
                    if (content.plan.canUpdateImage) ...[
                      const SizedBox(height: 16),
                      SectionPanel(
                        title: '画像',
                        child: ImageUpdateField(
                          currentImageUrl: content.imageUrl,
                          selectedImage: _selectedImage,
                          imageAspectRatio: content.imageAspectRatio,
                          crop: _imageCrop,
                          onCropChanged: (crop) {
                            setState(() => _imageCrop = crop);
                          },
                          onInteractionStart: _dismissKeyboard,
                          onResetCrop: () {
                            _dismissKeyboard();
                            setState(
                              () => _imageCrop = const ImageCrop.initial(),
                            );
                          },
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
      ),
    );
  }
}
