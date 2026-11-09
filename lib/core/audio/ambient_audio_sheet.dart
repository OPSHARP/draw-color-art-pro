import 'package:flutter/material.dart';
import 'ambient_sound_service.dart';
import 'sound_effect_service.dart';
import '../constants/design_tokens.dart';

/// Modal bottom sheet for controlling relaxing ambient soundscapes & ASMR audio.
class AmbientAudioSheet extends StatefulWidget {
  const AmbientAudioSheet({super.key});

  static Future<void> show(BuildContext context) {
    SoundEffectService.instance.playPop();
    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const AmbientAudioSheet(),
    );
  }

  @override
  State<AmbientAudioSheet> createState() => _AmbientAudioSheetState();
}

class _AmbientAudioSheetState extends State<AmbientAudioSheet> {
  final _service = AmbientSoundService.instance;
  late bool _isPlaying;
  late AmbientSoundscape _selected;
  late double _volume;

  @override
  void initState() {
    super.initState();
    _isPlaying = _service.isPlaying;
    _selected = _service.currentSoundscape ?? AmbientSoundscape.rain;
    _volume = _service.volume;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, bottomInset + AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.headphones_rounded, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Relaxing ASMR & Soundscapes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Calming background audio for drawing & coloring', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Soundscape Cards List ──
          ...AmbientSoundscape.values.map((s) {
            final isSelected = _selected == s;
            final isPlayingThis = isSelected && _isPlaying;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () async {
                  SoundEffectService.instance.playPop();
                  setState(() {
                    _selected = s;
                    _isPlaying = true;
                  });
                  await _service.playSoundscape(s);
                },
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1)
                        : (isDark ? const Color(0xFF232338) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark ? Colors.white12 : Colors.black12),
                      width: isSelected ? 1.4 : 0.6,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getIconForSoundscape(s),
                        color: isSelected ? theme.colorScheme.primary : (isDark ? Colors.white70 : Colors.black54),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            Text(
                              s.description,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.grey,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isPlayingThis)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.graphic_eq_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text('PLAYING', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else if (isSelected)
                        const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: AppSpacing.sm),

          // ── Controls: Play/Pause & Volume Slider ──
          Row(
            children: [
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: _isPlaying ? Colors.amber[700] : theme.colorScheme.primary,
                ),
                icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                onPressed: () async {
                  SoundEffectService.instance.playPop();
                  if (_isPlaying) {
                    await _service.stop();
                    setState(() => _isPlaying = false);
                  } else {
                    await _service.playSoundscape(_selected);
                    setState(() => _isPlaying = true);
                  }
                },
              ),
              const SizedBox(width: 10),
              Icon(Icons.volume_down_rounded, size: 18, color: Colors.grey[500]),
              Expanded(
                child: Slider(
                  value: _volume,
                  onChanged: (val) {
                    setState(() => _volume = val);
                    _service.setVolume(val);
                  },
                ),
              ),
              Icon(Icons.volume_up_rounded, size: 18, color: Colors.grey[500]),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForSoundscape(AmbientSoundscape s) {
    return switch (s) {
      AmbientSoundscape.rain => Icons.water_drop_rounded,
      AmbientSoundscape.pencilASMR => Icons.edit_note_rounded,
      AmbientSoundscape.campfire => Icons.local_fire_department_rounded,
      AmbientSoundscape.lofiChill => Icons.music_note_rounded,
      AmbientSoundscape.forestBreeze => Icons.air_rounded,
    };
  }
}
