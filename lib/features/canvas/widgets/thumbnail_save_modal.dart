import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';
import '../../export/services/export_service.dart';
import '../models/canvas_document.dart';

/// Modal dialog that allows creators to choose between JPG or PNG format
/// and saves their thumbnail directly to their phone's public Gallery & Google Photos album.
class ThumbnailSaveModal extends ConsumerStatefulWidget {
  const ThumbnailSaveModal({
    super.key,
    required this.document,
  });

  final CanvasDocument document;

  /// Show this modal sheet from any context.
  static Future<String?> show(BuildContext context, CanvasDocument document) {
    SoundEffectService.instance.playPop();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ThumbnailSaveModal(document: document),
    );
  }

  @override
  ConsumerState<ThumbnailSaveModal> createState() => _ThumbnailSaveModalState();
}

class _ThumbnailSaveModalState extends ConsumerState<ThumbnailSaveModal> {
  ExportFormat _selectedFormat = ExportFormat.png;
  double _scale = 1.0;
  bool _isSaving = false;
  String? _savedPath;
  String? _errorMessage;

  Future<void> _saveToGallery() async {
    SoundEffectService.instance.playWhoosh();
    HapticFeedback.mediumImpact();

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final config = ExportConfig(
        format: _selectedFormat,
        scale: _scale,
        quality: 95,
        includeBackground: true,
      );

      final filePath = await ExportService.instance.saveToGallery(
        widget.document,
        config: config,
      );

      SoundEffectService.instance.playCelebration();
      HapticFeedback.heavyImpact();

      if (mounted) {
        setState(() {
          _isSaving = false;
          _savedPath = filePath;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _shareFile() async {
    if (_savedPath == null) return;
    SoundEffectService.instance.playPop();
    HapticFeedback.lightImpact();
    await Share.shareXFiles(
      [XFile(_savedPath!)],
      text: 'Check out my new thumbnail: ${widget.document.name}!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = (widget.document.width * _scale).round();
    final height = (widget.document.height * _scale).round();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18182E) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        max(36.0, MediaQuery.paddingOf(context).bottom + AppSpacing.md),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_savedPath != null) ...[
              _buildSuccessView(context, isDark, width, height),
            ] else ...[
              _buildConfigView(context, isDark, width, height),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigView(BuildContext context, bool isDark, int width, int height) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF007F), Color(0xFFFF5F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.photo_library_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Save Thumbnail to Gallery',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Choose JPG or PNG for instant Photos sync',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Preview metadata badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF22223D) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.aspect_ratio_rounded,
                size: 18,
                color: Color(0xFFFF007F),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.document.name} • $width×$height',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF007F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _selectedFormat == ExportFormat.png ? 'PNG' : 'JPG',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF007F),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Format Selection Title
        Text(
          'CHOOSE IMAGE FORMAT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),

        // PNG Option Card
        _buildFormatCard(
          format: ExportFormat.png,
          title: 'PNG (Lossless High Quality)',
          subtitle: 'Best for YouTube, TikTok & Web • Razor-sharp text, outlines & gradients',
          badge: 'RECOMMENDED',
          badgeColor: const Color(0xFF00B894),
          icon: Icons.image_rounded,
          isSelected: _selectedFormat == ExportFormat.png,
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        // JPG Option Card
        _buildFormatCard(
          format: ExportFormat.jpeg,
          title: 'JPG / JPEG (Optimized & Compact)',
          subtitle: '95% photo quality with smaller file size • Ideal for fast mobile sharing',
          badge: 'COMPACT',
          badgeColor: const Color(0xFF0984E3),
          icon: Icons.photo_size_select_actual_rounded,
          isSelected: _selectedFormat == ExportFormat.jpeg,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.md),

        // Resolution Multiplier Tabs
        Row(
          children: [
            Text(
              'OUTPUT RESOLUTION:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
            const Spacer(),
            _buildScaleChip(1.0, 'Standard 1x', isDark),
            const SizedBox(width: 8),
            _buildScaleChip(2.0, 'Ultra-Res 2x', isDark),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade400),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Primary Save Button
        ElevatedButton(
          onPressed: _isSaving ? null : _saveToGallery,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF007F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 3,
            shadowColor: const Color(0xFFFF007F).withValues(alpha: 0.4),
          ),
          child: _isSaving
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Saving to Gallery & Photos...',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.download_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Save to Photos / Gallery (${_selectedFormat == ExportFormat.png ? 'PNG' : 'JPG'})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildFormatCard({
    required ExportFormat format,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        SoundEffectService.instance.playPop();
        HapticFeedback.selectionClick();
        setState(() => _selectedFormat = format);
      },
      child: AnimatedContainer(
        duration: AppAnimation.standard,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF007F).withValues(alpha: isDark ? 0.18 : 0.08)
              : (isDark ? const Color(0xFF22223D) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF007F) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF007F) : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? const Color(0xFFFF007F) : Colors.grey,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaleChip(double scale, String label, bool isDark) {
    final isSelected = _scale == scale;
    return GestureDetector(
      onTap: () {
        SoundEffectService.instance.playPop();
        HapticFeedback.selectionClick();
        setState(() => _scale = scale);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF007F)
              : (isDark ? const Color(0xFF22223D) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, bool isDark, int width, int height) {
    final fileName = _savedPath != null ? File(_savedPath!).uri.pathSegments.last : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00B894), Color(0xFF55EFC4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00B894).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Saved Directly to Gallery & Photos!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ready for instant upload to YouTube, TikTok, or Socials',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Path / Media info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF22223D) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _selectedFormat == ExportFormat.png
                        ? Icons.image_rounded
                        : Icons.photo_size_select_actual_rounded,
                    size: 16,
                    color: const Color(0xFF00B894),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_selectedFormat.label} Image • $width×$height',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                fileName,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _savedPath ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareFile,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share Artwork'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_savedPath),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B894),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
