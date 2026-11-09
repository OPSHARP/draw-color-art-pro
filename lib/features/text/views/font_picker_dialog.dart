import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/font_item.dart';
import '../services/font_catalog_service.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// Provider holding the currently selected font for typography styling.
final selectedFontProvider = StateProvider<FontItem>((ref) {
  return FontCatalogService.instance.defaultFont;
});

/// Provider holding custom typography styling parameters.
class TypographyStyleConfig {
  const TypographyStyleConfig({
    this.text = 'Creative Art Pro',
    this.fontSize = 32.0,
    this.isBold = false,
    this.isItalic = false,
    this.letterSpacing = 1.0,
    this.color = Colors.black,
    this.textAlign = TextAlign.center,
    this.textDecoration = TextDecoration.none,
    this.hasShadow = false,
    this.shadowOffsetX = 2.0,
    this.shadowOffsetY = 2.0,
    this.shadowBlur = 4.0,
    this.lineHeight = 1.3,
    this.textTransform = TextTransformMode.none,
    this.strokeColor = Colors.black,
    this.strokeWidth = 0.0,
    this.hasBackgroundBox = false,
    this.backgroundColor = const Color(0xFFD63031),
  });

  final String text;
  final double fontSize;
  final bool isBold;
  final bool isItalic;
  final double letterSpacing;
  final Color color;
  final TextAlign textAlign;
  final TextDecoration textDecoration;
  final bool hasShadow;
  final double shadowOffsetX;
  final double shadowOffsetY;
  final double shadowBlur;
  final double lineHeight;
  final TextTransformMode textTransform;
  final Color strokeColor;
  final double strokeWidth;
  final bool hasBackgroundBox;
  final Color backgroundColor;

  TypographyStyleConfig copyWith({
    String? text,
    double? fontSize,
    bool? isBold,
    bool? isItalic,
    double? letterSpacing,
    Color? color,
    TextAlign? textAlign,
    TextDecoration? textDecoration,
    bool? hasShadow,
    double? shadowOffsetX,
    double? shadowOffsetY,
    double? shadowBlur,
    double? lineHeight,
    TextTransformMode? textTransform,
    Color? strokeColor,
    double? strokeWidth,
    bool? hasBackgroundBox,
    Color? backgroundColor,
  }) {
    return TypographyStyleConfig(
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      color: color ?? this.color,
      textAlign: textAlign ?? this.textAlign,
      textDecoration: textDecoration ?? this.textDecoration,
      hasShadow: hasShadow ?? this.hasShadow,
      shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
      shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      lineHeight: lineHeight ?? this.lineHeight,
      textTransform: textTransform ?? this.textTransform,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      hasBackgroundBox: hasBackgroundBox ?? this.hasBackgroundBox,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  /// Apply the transform mode to text.
  String transformedText(String input) => switch (textTransform) {
    TextTransformMode.uppercase => input.toUpperCase(),
    TextTransformMode.lowercase => input.toLowerCase(),
    TextTransformMode.titleCase => input.split(' ').map((w) =>
        w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
    ).join(' '),
    TextTransformMode.none => input,
  };
}

/// Text transform modes.
enum TextTransformMode {
  none('None'),
  uppercase('UPPERCASE'),
  lowercase('lowercase'),
  titleCase('Title Case');

  const TextTransformMode(this.label);
  final String label;
}

final typographyConfigProvider = StateProvider<TypographyStyleConfig>((ref) {
  return const TypographyStyleConfig();
});

/// Modal sheet to browse, search, and pick from 100+ Google Fonts.
class FontPickerDialog extends ConsumerStatefulWidget {
  const FontPickerDialog({super.key, this.onApplyText, this.initialText});

  final void Function(String text, TextStyle style)? onApplyText;
  final String? initialText;

  static void show(
    BuildContext context, {
    void Function(String text, TextStyle style)? onApplyText,
    void Function(String text, TextStyle style)? onApply,
    String? initialText,
  }) {
    SoundEffectService.instance.playPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FontPickerDialog(
        onApplyText: onApplyText ?? onApply,
        initialText: initialText,
      ),
    );
  }

  @override
  ConsumerState<FontPickerDialog> createState() => _FontPickerDialogState();
}

class _FontPickerDialogState extends ConsumerState<FontPickerDialog> {
  FontCategory _selectedCategory = FontCategory.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    final defaultText = widget.initialText ?? ref.read(typographyConfigProvider).text;
    _textController = TextEditingController(
      text: defaultText.isNotEmpty ? defaultText : 'Creative Art',
    );
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(typographyConfigProvider.notifier).state =
              ref.read(typographyConfigProvider).copyWith(text: widget.initialText!);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedFont = ref.watch(selectedFontProvider);
    final typoConfig = ref.watch(typographyConfigProvider);
    final filteredFonts = FontCatalogService.instance.filter(
      category: _selectedCategory,
      query: _searchQuery,
    );

    final currentStyle = selectedFont.applyStyle(
      TextStyle(
        fontSize: typoConfig.fontSize,
        fontWeight: typoConfig.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: typoConfig.isItalic ? FontStyle.italic : FontStyle.normal,
        letterSpacing: typoConfig.letterSpacing,
        color: typoConfig.color,
        decoration: typoConfig.textDecoration,
        shadows: typoConfig.hasShadow
            ? [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: Offset(typoConfig.shadowOffsetX, typoConfig.shadowOffsetY),
                  blurRadius: typoConfig.shadowBlur,
                ),
              ]
            : null,
        height: typoConfig.lineHeight,
      ),
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.sm, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.text_fields_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100+ Fonts & Typography',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${FontCatalogService.instance.totalCount} Google Fonts for Art Styling',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    SoundEffectService.instance.playPop();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),

          // Live Text Preview Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF28283E) : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: isDark ? Colors.white12 : (theme.dividerTheme.color ?? const Color(0xFFE5E7EB))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Enter text to style...',
                          isDense: true,
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        onChanged: (val) {
                          ref.read(typographyConfigProvider.notifier).state =
                              typoConfig.copyWith(text: val.isEmpty ? 'Creative Art Pro' : val);
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        selectedFont.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 10),
                // Styled Text Display (with Live Background Box & Stroke Outline)
                Container(
                  alignment: typoConfig.textAlign == TextAlign.left
                      ? Alignment.centerLeft
                      : typoConfig.textAlign == TextAlign.right
                          ? Alignment.centerRight
                          : Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: typoConfig.hasBackgroundBox
                        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
                        : EdgeInsets.zero,
                    decoration: typoConfig.hasBackgroundBox
                        ? BoxDecoration(
                            color: typoConfig.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    child: Stack(
                      alignment: typoConfig.textAlign == TextAlign.left
                          ? Alignment.centerLeft
                          : typoConfig.textAlign == TextAlign.right
                              ? Alignment.centerRight
                              : Alignment.center,
                      children: [
                        if (typoConfig.strokeWidth > 0)
                          Text(
                            typoConfig.transformedText(typoConfig.text),
                            style: selectedFont.applyStyle(TextStyle(
                              fontSize: typoConfig.fontSize,
                              fontWeight: typoConfig.isBold ? FontWeight.bold : FontWeight.normal,
                              fontStyle: typoConfig.isItalic ? FontStyle.italic : FontStyle.normal,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = typoConfig.strokeWidth
                                ..strokeCap = StrokeCap.round
                                ..strokeJoin = StrokeJoin.round
                                ..color = typoConfig.strokeColor,
                            )),
                            textAlign: typoConfig.textAlign,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          typoConfig.transformedText(typoConfig.text),
                          style: currentStyle,
                          textAlign: typoConfig.textAlign,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                // Quick Controls: Bold, Italic, Size
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.format_bold_rounded,
                        color: typoConfig.isBold ? theme.colorScheme.primary : Colors.grey,
                      ),
                      onPressed: () {
                        SoundEffectService.instance.playPop();
                        ref.read(typographyConfigProvider.notifier).state =
                            typoConfig.copyWith(isBold: !typoConfig.isBold);
                      },
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.format_italic_rounded,
                        color: typoConfig.isItalic ? theme.colorScheme.primary : Colors.grey,
                      ),
                      onPressed: () {
                        SoundEffectService.instance.playPop();
                        ref.read(typographyConfigProvider.notifier).state =
                            typoConfig.copyWith(isItalic: !typoConfig.isItalic);
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text('Size:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Expanded(
                      child: Slider(
                        value: typoConfig.fontSize,
                        min: 14.0,
                        max: 72.0,
                        onChanged: (val) {
                          ref.read(typographyConfigProvider.notifier).state =
                              typoConfig.copyWith(fontSize: val);
                        },
                      ),
                    ),
                    Text('${typoConfig.fontSize.toInt()}pt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                // Advanced Controls: Alignment, Underline, Strikethrough, Shadow, Transform, Outline, Box
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Alignment
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Text Alignment',
                        icon: Icon(
                          typoConfig.textAlign == TextAlign.left
                              ? Icons.format_align_left_rounded
                              : typoConfig.textAlign == TextAlign.center
                                  ? Icons.format_align_center_rounded
                                  : Icons.format_align_right_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () {
                          SoundEffectService.instance.playPop();
                          final next = typoConfig.textAlign == TextAlign.center
                              ? TextAlign.right
                              : typoConfig.textAlign == TextAlign.right
                                  ? TextAlign.left
                                  : TextAlign.center;
                          ref.read(typographyConfigProvider.notifier).state =
                              typoConfig.copyWith(textAlign: next);
                        },
                      ),
                      // Underline
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Underline',
                        icon: Icon(
                          Icons.format_underlined_rounded,
                          size: 18,
                          color: typoConfig.textDecoration == TextDecoration.underline
                              ? theme.colorScheme.primary
                              : Colors.grey,
                        ),
                        onPressed: () {
                          SoundEffectService.instance.playPop();
                          ref.read(typographyConfigProvider.notifier).state =
                              typoConfig.copyWith(
                            textDecoration: typoConfig.textDecoration == TextDecoration.underline
                                ? TextDecoration.none
                                : TextDecoration.underline,
                          );
                        },
                      ),
                      // Strikethrough
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Strikethrough',
                        icon: Icon(
                          Icons.format_strikethrough_rounded,
                          size: 18,
                          color: typoConfig.textDecoration == TextDecoration.lineThrough
                              ? theme.colorScheme.primary
                              : Colors.grey,
                        ),
                        onPressed: () {
                          SoundEffectService.instance.playPop();
                          ref.read(typographyConfigProvider.notifier).state =
                              typoConfig.copyWith(
                            textDecoration: typoConfig.textDecoration == TextDecoration.lineThrough
                                ? TextDecoration.none
                                : TextDecoration.lineThrough,
                          );
                        },
                      ),
                      // Shadow toggle
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Drop Shadow',
                        icon: Icon(
                          Icons.blur_on_rounded,
                          size: 18,
                          color: typoConfig.hasShadow ? theme.colorScheme.primary : Colors.grey,
                        ),
                        onPressed: () {
                          SoundEffectService.instance.playPop();
                          ref.read(typographyConfigProvider.notifier).state =
                              typoConfig.copyWith(hasShadow: !typoConfig.hasShadow);
                        },
                      ),
                      // Outline Stroke Toggle
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Thumbnail Outline Stroke',
                        icon: Icon(
                          Icons.line_weight_rounded,
                          size: 18,
                          color: typoConfig.strokeWidth > 0 ? theme.colorScheme.primary : Colors.grey,
                        ),
                        onPressed: () {
                          SoundEffectService.instance.playPop();
                          final nextWidth = typoConfig.strokeWidth == 0.0
                              ? 3.5
                              : typoConfig.strokeWidth <= 3.5
                                  ? 6.0
                                  : 0.0;
                          ref.read(typographyConfigProvider.notifier).state =
                              typoConfig.copyWith(strokeWidth: nextWidth);
                        },
                      ),
                      // Background Box Toggle
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Thumbnail Background Pill Box',
                        icon: Icon(
                          Icons.featured_play_list_rounded,
                          size: 18,
                          color: typoConfig.hasBackgroundBox ? theme.colorScheme.primary : Colors.grey,
                        ),
                        onPressed: () {
                          SoundEffectService.instance.playPop();
                          ref.read(typographyConfigProvider.notifier).state =
                              typoConfig.copyWith(hasBackgroundBox: !typoConfig.hasBackgroundBox);
                        },
                      ),
                      // Transform (Uppercase / TitleCase / None)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          SoundEffectService.instance.playPop();
                          final next = typoConfig.textTransform == TextTransformMode.none
                              ? TextTransformMode.uppercase
                              : typoConfig.textTransform == TextTransformMode.uppercase
                                  ? TextTransformMode.titleCase
                                  : TextTransformMode.none;
                          ref.read(typographyConfigProvider.notifier).state =
                              typoConfig.copyWith(textTransform: next);
                        },
                        child: Text(
                          typoConfig.textTransform == TextTransformMode.none
                              ? 'Aa (Normal)'
                              : typoConfig.textTransform == TextTransformMode.uppercase
                                  ? 'AA (UPPER)'
                                  : 'Ab (Title)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: typoConfig.textTransform != TextTransformMode.none
                                ? theme.colorScheme.primary
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),
                // ── Thumbnail Style Presets ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Styles: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFFFFD700).withValues(alpha: 0.2),
                        avatar: const Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFFFF9800)),
                        label: const Text('YouTube Punchy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          SoundEffectService.instance.playPop();
                          ref.read(typographyConfigProvider.notifier).state = typoConfig.copyWith(
                            isBold: true,
                            color: const Color(0xFFFFEB3B),
                            strokeWidth: 4.5,
                            strokeColor: Colors.black,
                            hasShadow: true,
                            hasBackgroundBox: false,
                            textTransform: TextTransformMode.uppercase,
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFFD63031).withValues(alpha: 0.2),
                        avatar: const Icon(Icons.campaign_rounded, size: 14, color: Color(0xFFD63031)),
                        label: const Text('Breaking Box', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          SoundEffectService.instance.playPop();
                          ref.read(typographyConfigProvider.notifier).state = typoConfig.copyWith(
                            isBold: true,
                            color: Colors.white,
                            hasBackgroundBox: true,
                            backgroundColor: const Color(0xFFD63031),
                            strokeWidth: 0.0,
                            hasShadow: true,
                            textTransform: TextTransformMode.uppercase,
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                        avatar: const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF00CEC9)),
                        label: const Text('Neon Cyber', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          SoundEffectService.instance.playPop();
                          ref.read(typographyConfigProvider.notifier).state = typoConfig.copyWith(
                            isBold: true,
                            color: const Color(0xFF00F0FF),
                            hasShadow: true,
                            shadowBlur: 8.0,
                            strokeWidth: 0.0,
                            hasBackgroundBox: false,
                            textTransform: TextTransformMode.uppercase,
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFFFFA000).withValues(alpha: 0.2),
                        avatar: const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFFFA000)),
                        label: const Text('Gaming Gold', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          SoundEffectService.instance.playPop();
                          ref.read(typographyConfigProvider.notifier).state = typoConfig.copyWith(
                            isBold: true,
                            color: const Color(0xFFFFC107),
                            strokeWidth: 3.5,
                            strokeColor: const Color(0xFF2D1600),
                            hasShadow: true,
                            hasBackgroundBox: false,
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: const Text('Reset', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          SoundEffectService.instance.playPop();
                          ref.read(typographyConfigProvider.notifier).state = typoConfig.copyWith(
                            color: Colors.black,
                            isBold: false,
                            strokeWidth: 0.0,
                            hasBackgroundBox: false,
                            hasShadow: false,
                            textTransform: TextTransformMode.none,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search 100+ fonts (e.g. Playfair, Caveat, Orbitron...)',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          const SizedBox(height: 8),

          // Category Chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: FontCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat.label),
                    selected: isSelected,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : null,
                    ),
                    selectedColor: theme.colorScheme.primary,
                    showCheckmark: false,
                    onSelected: (_) {
                      SoundEffectService.instance.playPop();
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 6),
          const Divider(height: 1),

          // Fonts List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: filteredFonts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final font = filteredFonts[index];
                final isSelected = selectedFont.name == font.name;

                return InkWell(
                  onTap: () {
                    SoundEffectService.instance.playPop();
                    ref.read(selectedFontProvider.notifier).state = font;
                  },
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: isSelected
                          ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                font.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                font.category.label,
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            typoConfig.text,
                            style: font.applyStyle(
                              TextStyle(fontSize: 18, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 20),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action Button (Protected from Navigation Keys)
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              MediaQuery.paddingOf(context).bottom > 0
                  ? MediaQuery.paddingOf(context).bottom + AppSpacing.xs
                  : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? Colors.white12 : (theme.dividerTheme.color ?? const Color(0xFFE5E7EB)))),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                SoundEffectService.instance.playCelebration();
                Navigator.of(context).pop();
                final appliedText = typoConfig.transformedText(typoConfig.text);
                widget.onApplyText?.call(appliedText, currentStyle);
              },
              icon: const Icon(Icons.check_rounded),
              label: Text('Use "${selectedFont.name}" Font'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
