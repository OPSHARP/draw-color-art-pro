import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tools.dart';
import '../providers/canvas_providers.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/audio/sound_effect_service.dart';

/// Primary vertical toolbar with drawing tools.
///
/// Per PRD: Brush, Pencil, Pen, Marker, Fill, Eraser, Eyedropper,
/// Selection, Transform, Shape.
class PrimaryToolbar extends ConsumerWidget {
  const PrimaryToolbar({super.key});

  static const _tools = [
    (DrawingTool.brush, Icons.brush_rounded),
    (DrawingTool.pencil, Icons.create_rounded),
    (DrawingTool.pen, Icons.edit_rounded),
    (DrawingTool.marker, Icons.format_paint_rounded),
    (DrawingTool.fill, Icons.format_color_fill_rounded),
    (DrawingTool.eraser, Icons.auto_fix_high_rounded),
    (DrawingTool.eyedropper, Icons.colorize_rounded),
    (DrawingTool.selection, Icons.select_all_rounded),
    (DrawingTool.transform, Icons.open_with_rounded),
    (DrawingTool.shape, Icons.crop_square_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);
    final undoRedo = ref.watch(undoRedoProvider);

    return Container(
      width: 52,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.xxs),
          for (final (tool, icon) in _tools)
            _ToolButton(
              tool: tool,
              icon: icon,
              isActive: activeTool == tool,
              onTap: () {
                SoundEffectService.instance.playPop();
                ref.read(activeToolProvider.notifier).selectTool(tool);
              },
            ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(height: 4),
          // ── Feature Layout: Undo Button ──
          _FeatureActionButton(
            icon: Icons.undo_rounded,
            tooltip: 'Undo (Ctrl+Z)',
            isEnabled: undoRedo.canUndo,
            onTap: () {
              SoundEffectService.instance.playWhoosh();
              ref.read(undoRedoProvider.notifier).undo();
            },
          ),
          // ── Feature Layout: Redo Button ──
          _FeatureActionButton(
            icon: Icons.redo_rounded,
            tooltip: 'Redo (Ctrl+Y)',
            isEnabled: undoRedo.canRedo,
            onTap: () {
              SoundEffectService.instance.playPop();
              ref.read(undoRedoProvider.notifier).redo();
            },
          ),
          const SizedBox(height: AppSpacing.xxs),
        ],
      ),
    );
  }
}

class _FeatureActionButton extends StatelessWidget {
  const _FeatureActionButton({
    required this.icon,
    required this.tooltip,
    required this.isEnabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: 1,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: AnimatedContainer(
              duration: AppAnimation.micro,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isEnabled
                    ? theme.colorScheme.primary
                    : const Color(0xFFD1D5DB),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tool,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final DrawingTool tool;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message:
          tool.shortcutKey != null
              ? '${tool.label} (${tool.shortcutKey})'
              : tool.label,
      preferBelow: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: 1,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: AnimatedContainer(
              duration: AppAnimation.micro,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                    isActive
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border:
                    isActive
                        ? Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        )
                        : null,
              ),
              child: Icon(
                icon,
                size: 20,
                color:
                    isActive
                        ? theme.colorScheme.primary
                        : theme.iconTheme.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
