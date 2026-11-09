import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/constants/app_version.dart';

/// Full Terms of Service screen emphasizing artist rights, ownership, and service terms.
/// Updated for Draw Color Art Pro v1.0.2 (Build 3).
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Hero Banner ──
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                  const Color(0xFFFF6B9D).withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFFFF6B9D)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.brush_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Artist Ownership',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'You own everything you create. Free for personal & commercial use.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Section 1: Ownership ──
          const _TermsCard(
            icon: Icons.palette_rounded,
            title: '1. Intellectual Property & Artwork Ownership',
            content:
                'You retain full, exclusive copyright and intellectual property rights '
                'to all original artworks, illustrations, sketches, layer compositions, and drawings '
                'that you create using Draw Color Art Pro. We claim zero royalties, zero license fees, '
                'and zero ownership claims over your work.',
          ),

          // ── Section 2: Commercial & Personal Use ──
          const _TermsCard(
            icon: Icons.storefront_rounded,
            title: '2. Commercial & Personal Freedom',
            content:
                'You are free to use your exported artwork for both personal and commercial endeavors, '
                'including prints, merchandise, game assets, digital publications, client projects, '
                'and social media monetization, with no attribution required.',
          ),

          // ── Section 3: App Features & Free Access ──
          const _TermsCard(
            icon: Icons.lock_open_rounded,
            title: '3. 100% Free Creative Suite',
            content:
                'All features within Draw Color Art Pro—including unlimited layer creation, blend modes, '
                'high-refresh rate rendering (up to 120Hz/144Hz/165Hz), 3-point perspective guides, QuickShape '
                'recognition, ASMR audio synthesizer, 200 procedural coloring templates across 16 categories, '
                'and AR camera tracing—are provided completely free of charge without mandatory subscriptions or paywalls.',
          ),

          // ── Section 4: Advertising & Ad-Blocker Fair Use Policy ──
          const _TermsCard(
            icon: Icons.ads_click_rounded,
            title: '4. Advertising & Fair Support Policy',
            content:
                'To maintain and support continuous updates for free, Draw Color Art Pro integrates polite '
                'Google AdMob advertisements. Interstitial ads are governed by strict minimum 6-minute cooldowns '
                'to preserve uninterrupted drawing flow.\n\n'
                '• Ad Blocker Detection: When an active ad-blocker or private ad-blocking DNS is detected, the app '
                'displays a lightweight reminder toast every 10 seconds requesting you to whitelist the app. '
                'When ad-blocking is disabled, the app runs completely free of reminder notices.',
          ),

          // ── Section 5: Acceptable Use ──
          const _TermsCard(
            icon: Icons.thumb_up_alt_rounded,
            title: '5. Acceptable Use',
            content:
                'You agree to use Draw Color Art Pro in compliance with all applicable local, national, '
                'and international laws. You may not reverse engineer, decompile, or distribute '
                'malicious modifications of the application package.',
          ),

          // ── Section 6: Local Storage & Backups ──
          const _TermsCard(
            icon: Icons.cloud_off_rounded,
            title: '6. Local Storage & Artist Backups',
            content:
                'Because the application operates entirely offline on-device to safeguard your personal privacy, '
                'your artwork is saved directly to your device storage. We strongly recommend regularly exporting '
                'important master files (PNG/JPEG) to your preferred cloud drive or external computer storage '
                'to prevent accidental data loss in the event of device damage or reset.',
          ),

          // ── Section 7: Disclaimer & Limitation of Liability ──
          const _TermsCard(
            icon: Icons.gavel_rounded,
            title: '7. Disclaimer & Limitation of Liability',
            content:
                'Draw Color Art Pro is provided "as is" and "as available" without warranties of any kind. '
                'To the maximum extent permitted by law, the developers shall not be liable for any direct, '
                'indirect, incidental, or consequential damages resulting from the use or inability to use '
                'the application, including data loss resulting from device malfunction.',
          ),

          // ── Section 8: Developer Contact & Inquiries ──
          const _TermsCard(
            icon: Icons.contact_support_rounded,
            title: '8. Developer Contact & Inquiries',
            content:
                'For inquiries, artist rights questions, commercial licensing, or assistance:\n\n'
                '• Developer: Sachin Raghav\n'
                '• Phone: +91 9557754705\n'
                '• Email: sachinraghav9090@gmail.com\n'
                '• Location: India',
          ),

          // ── Footer ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: Text(
                'Effective Date: September 2026 • Draw Color Art Pro ${AppVersion.fullVersion}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsCard extends StatelessWidget {
  const _TermsCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  final IconData icon;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: const Color(0xFF6C5CE7),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
