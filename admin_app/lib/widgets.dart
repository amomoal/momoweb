import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';

class HeaderPanel extends StatelessWidget {
  const HeaderPanel({
    required this.content,
    required this.isDemoMode,
    required this.publicSiteUrl,
    super.key,
  });

  final SiteContent content;
  final bool isDemoMode;
  final String publicSiteUrl;

  Future<void> _openPublicSite(BuildContext context) async {
    final uri = Uri.tryParse(publicSiteUrl);
    if (uri == null) return;

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('サイトを開けませんでした')));
  }

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: content.siteName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                  content.plan.canUpdateImage
                      ? 'お知らせと画像を更新できます'
                      : 'お知らせを更新できます',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (isDemoMode)
                const Chip(
                  label: Text('デモ'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (publicSiteUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(
              publicSiteUrl,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openPublicSite(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('サイトを開く'),
            ),
          ],
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
    required this.imageAspectRatio,
    required this.crop,
    required this.onCropChanged,
    required this.onInteractionStart,
    required this.onResetCrop,
    required this.onPickImage,
    required this.onClearImage,
    super.key,
  });

  final String? currentImageUrl;
  final PickedImage? selectedImage;
  final double imageAspectRatio;
  final ImageCrop crop;
  final ValueChanged<ImageCrop> onCropChanged;
  final VoidCallback onInteractionStart;
  final VoidCallback onResetCrop;
  final VoidCallback onPickImage;
  final VoidCallback? onClearImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ImageCropEditor(
          currentImageUrl: currentImageUrl,
          selectedImage: selectedImage,
          aspectRatio: imageAspectRatio,
          crop: crop,
          onCropChanged: onCropChanged,
          onInteractionStart: onInteractionStart,
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
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: '中央に戻す',
              onPressed: onResetCrop,
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
      ],
    );
  }
}

class ImageCropEditor extends StatefulWidget {
  const ImageCropEditor({
    required this.currentImageUrl,
    required this.selectedImage,
    required this.aspectRatio,
    required this.crop,
    required this.onCropChanged,
    required this.onInteractionStart,
    super.key,
  });

  final String? currentImageUrl;
  final PickedImage? selectedImage;
  final double aspectRatio;
  final ImageCrop crop;
  final ValueChanged<ImageCrop> onCropChanged;
  final VoidCallback onInteractionStart;

  @override
  State<ImageCropEditor> createState() => _ImageCropEditorState();
}

class _ImageCropEditorState extends State<ImageCropEditor> {
  late ImageCrop _startCrop;

  void _handleScaleStart(ScaleStartDetails details) {
    widget.onInteractionStart();
    _startCrop = widget.crop;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, Size frameSize) {
    final nextScale = (_startCrop.scale * details.scale).clamp(1.0, 4.0);
    final offsetLimit = cropOffsetLimit(nextScale);
    final nextOffsetX =
        (_startCrop.offsetX +
                (details.focalPointDelta.dx / frameSize.width) * 100)
            .clamp(-offsetLimit, offsetLimit)
            .toDouble();
    final nextOffsetY =
        (_startCrop.offsetY +
                (details.focalPointDelta.dy / frameSize.height) * 100)
            .clamp(-offsetLimit, offsetLimit)
            .toDouble();

    widget.onCropChanged(
      ImageCrop(scale: nextScale, offsetX: nextOffsetX, offsetY: nextOffsetY),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final frameWidth = maxWidth;
        final frameHeight = frameWidth / widget.aspectRatio;
        final canvasHeight = frameHeight + 96;
        final frameTop = (canvasHeight - frameHeight) / 2;
        final frameRect = Rect.fromLTWH(0, frameTop, frameWidth, frameHeight);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onInteractionStart,
          onScaleStart: _handleScaleStart,
          onScaleUpdate: (details) {
            _handleScaleUpdate(details, Size(frameWidth, frameHeight));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xff211d1a)),
              child: SizedBox(
                height: canvasHeight,
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fromRect(
                        rect: frameRect,
                        child: Transform.translate(
                          offset: Offset(
                            frameWidth * widget.crop.offsetX / 100,
                            frameHeight * widget.crop.offsetY / 100,
                          ),
                          child: Transform.scale(
                            scale: widget.crop.scale,
                            child: _CropImage(
                              currentImageUrl: widget.currentImageUrl,
                              selectedImage: widget.selectedImage,
                            ),
                          ),
                        ),
                      ),
                      _CropOverlay(frameRect: frameRect),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CropImage extends StatelessWidget {
  const _CropImage({
    required this.currentImageUrl,
    required this.selectedImage,
  });

  final String? currentImageUrl;
  final PickedImage? selectedImage;

  @override
  Widget build(BuildContext context) {
    if (selectedImage != null) {
      return Image.memory(selectedImage!.bytes, fit: BoxFit.cover);
    }

    if (currentImageUrl == null) {
      return const ColoredBox(
        color: Color(0xfff1eee8),
        child: Center(child: Text('現在の画像はありません')),
      );
    }

    return Image.network(
      currentImageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const ColoredBox(
          color: Color(0xfff1eee8),
          child: Center(child: Text('画像を表示できません')),
        );
      },
    );
  }
}

class _CropOverlay extends StatelessWidget {
  const _CropOverlay({required this.frameRect});

  final Rect frameRect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: width,
              height: frameRect.top,
              child: const ColoredBox(color: Color(0x99000000)),
            ),
            Positioned(
              left: 0,
              top: frameRect.bottom,
              width: width,
              height: height - frameRect.bottom,
              child: const ColoredBox(color: Color(0x99000000)),
            ),
            Positioned(
              left: 0,
              top: frameRect.top,
              width: frameRect.left,
              height: frameRect.height,
              child: const ColoredBox(color: Color(0x99000000)),
            ),
            Positioned(
              left: frameRect.right,
              top: frameRect.top,
              width: width - frameRect.right,
              height: frameRect.height,
              child: const ColoredBox(color: Color(0x99000000)),
            ),
            Positioned.fromRect(
              rect: frameRect,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ConfirmUpdateDialog extends StatelessWidget {
  const ConfirmUpdateDialog({
    required this.siteName,
    required this.info,
    required this.image,
    required this.imageAspectRatio,
    required this.imageCrop,
    super.key,
  });

  final String siteName;
  final String info;
  final PickedImage? image;
  final double? imageAspectRatio;
  final ImageCrop? imageCrop;

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
                child: AspectRatio(
                  aspectRatio: imageAspectRatio ?? 16 / 9,
                  child: Transform.translate(
                    offset: Offset(
                      280 * (imageCrop?.offsetX ?? 0) / 100,
                      160 * (imageCrop?.offsetY ?? 0) / 100,
                    ),
                    child: Transform.scale(
                      scale: imageCrop?.scale ?? 1,
                      child: Image.memory(image!.bytes, fit: BoxFit.cover),
                    ),
                  ),
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

double cropOffsetLimit(double scale) {
  return ((scale.clamp(1.0, 4.0) - 1) * 50).toDouble();
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
