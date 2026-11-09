import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/constants/app_version.dart';

/// Full, transparent, and compliant Privacy Policy screen.
/// Updated for Draw Color Art Pro v1.0.2 (Build 3).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                  theme.colorScheme.secondary.withValues(alpha: 0.1),
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
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
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
                        '100% Privacy by Design',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your artwork remains 100% on your device. Zero cloud tracking.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Section 1: Local-First ──
          const _PolicyCard(
            icon: Icons.offline_pin_rounded,
            title: '1. Local-First & Zero Telemetry',
            content:
                'Draw Color Art Pro operates strictly on a local-first architecture. '
                'All illustrations, sketches, layer structures, undo histories, color palettes, '
                'and canvas configurations are stored exclusively on your device. '
                'We do not operate proprietary servers to store, access, view, or sell your art. '
                'No user account, email address, password, or sign-in is ever required.',
          ),

          // ── Section 2: Advertising & Google AdMob ──
          const _PolicyCard(
            icon: Icons.ads_click_rounded,
            title: '2. Third-Party Advertising (Google AdMob)',
            content:
                'To keep Draw Color Art Pro 100% free and accessible to all creators without '
                'subscriptions or paywalls, we display advertisements provided by Google AdMob.\n\n'
                '• Ad Network: Google Mobile Ads (AdMob) Network\n'
                '• Responsive Ad Formats: Banner ads, non-intrusive interstitial ads (with minimum 6-minute cooldowns to preserve drawing flow), and app-open transitions.\n'
                '• What Google AdMob May Collect:\n'
                'Google AdMob may automatically collect pseudonymous device information, such as your '
                'Google Advertising ID (Android) or Identifier for Advertisers (IDFA on iOS), '
                'approximate coarse location based on IP address, device model, operating system version, '
                'and ad interaction statistics.\n\n'
                '• Purpose of Processing:\n'
                'This information is utilized by Google to deliver, measure, and optimize advertising '
                'content, combat fraudulent activity, and ensure compliance with ad quality guidelines.\n\n'
                '• Google Privacy Policy:\n'
                'For complete details on how Google handles advertising data, visit: '
                'https://policies.google.com/privacy and https://policies.google.com/technologies/ads',
          ),

          // ── Section 3: Ad-Blocker & Custom DNS Detection Policy ──
          const _PolicyCard(
            icon: Icons.shield_outlined,
            title: '3. Ad-Blocker & Custom Private DNS Detection Policy',
            content:
                'Because Draw Color Art Pro is provided entirely free without subscriptions, '
                'our service performs lightweight, local network domain accessibility checks to verify that '
                'essential AdMob ad delivery domains are reachable.\n\n'
                '• Detection Mechanism: The application performs periodic DNS lookup checks locally on-device. '
                'No personal browsing history or DNS logs are inspected, transmitted, or stored.\n'
                '• Recurring Toast Notifications: When an active ad blocker, hosts sinkhole, or ad-blocking private DNS '
                '(e.g., AdGuard, NextDNS, Pi-hole, Blokada) is detected, the app displays a non-blocking toast reminder '
                'every 10 seconds requesting users to disable ad blocking or whitelist the application.\n'
                '• Normal Experience Without Ad Blocker: When no ad blocker or ad-blocking private DNS is running, '
                'ZERO notifications or toasts are displayed, and the application runs completely normally with standard responsive ads.',
          ),

          // ── Section 4: Device Permissions & Photo Picker ──
          const _PolicyCard(
            icon: Icons.verified_user_rounded,
            title: '4. Device Permissions & Android Photo Picker Compliance',
            content:
                'We adhere strictly to the latest Google Play Photo and Video Permissions policy:\n\n'
                '• Zero Broad Storage Access: Draw Color Art Pro DOES NOT request broad READ_EXTERNAL_STORAGE '
                'or READ_MEDIA_IMAGES permissions. We never have access to your wider photo library.\n'
                '• Android System Photo Picker: When importing a reference image or background photo, the secure '
                'system photo picker (MediaStore.ACTION_PICK_IMAGES) is invoked. Only the single image you explicitly '
                'select is granted temporary read access to the app.\n'
                '• Artwork Export: Rendered PNG/JPEG images are saved directly to your device storage using scoped '
                'storage mechanisms without requiring broad device file access.\n'
                '• Audio & Haptics: Used purely on-device for ASMR drawing sound synthesis and haptic feedback. '
                'No microphone or audio recordings are ever created or accessed.',
          ),

          // ── Section 5: High Refresh Rate Displays ──
          const _PolicyCard(
            icon: Icons.speed_rounded,
            title: '5. High Refresh Rate Display Performance (120Hz / 144Hz)',
            content:
                'Draw Color Art Pro optimizes hardware display modes to render at the highest supported refresh rate '
                '(90Hz, 120Hz, 144Hz, or 165Hz) on compatible Android devices for ultra-low latency stylus and touch drawing. '
                'This optimization utilizes native system window display mode APIs locally without collecting any hardware profiling data.',
          ),

          // ── Section 6: Google Play Flexible In-App Updates ──
          const _PolicyCard(
            icon: Icons.system_update_rounded,
            title: '6. Google Play Flexible In-App Updates',
            content:
                'The application uses the official Google Play In-App Update API to check whether a newer version '
                'is available in the Google Play Store. Flexible background downloads occur seamlessly while you continue '
                'drawing, and a gentle prompt notifies you once the download completes to install the update when convenient.',
          ),

          // ── Section 7: Opt-Out & User Rights (GDPR & CCPA) ──
          const _PolicyCard(
            icon: Icons.tune_rounded,
            title: '7. Your Rights & Ad Personalization Choices (GDPR / CCPA / CPRA)',
            content:
                'You maintain complete control over targeted advertising across your mobile device:\n\n'
                '• Android: Open Settings → Google → Ads → tap "Delete advertising ID" or "Reset advertising ID".\n'
                '• iOS: Open Settings → Privacy & Security → Tracking → toggle off tracking permissions, '
                'or Settings → Privacy & Security → Apple Advertising → turn off Personalized Ads.\n'
                '• GDPR (European Economic Area) & CCPA/CPRA (California): You have the right to request '
                'non-personalized ads, opt out of the sale/sharing of personal information, and request '
                'deletion of advertising identifiers through your device operating system settings.',
          ),

          // ── Section 8: Children & Family Policy (COPPA) ──
          const _PolicyCard(
            icon: Icons.family_restroom_rounded,
            title: '8. Children\'s Privacy (COPPA & Google Play Families)',
            content:
                'We take the safety of young creators seriously. We do not knowingly collect personal '
                'identifying information from children under 13 (or under 16 in applicable European jurisdictions). '
                'Advertisements served comply with Google Play Families Policy and COPPA standards, '
                'and where child-directed status is indicated, behavioral tracking and interest-based ad targeting are disabled.',
          ),

          // ── Section 9: Data Retention & Deletion ──
          const _PolicyCard(
            icon: Icons.cleaning_services_rounded,
            title: '9. Data Deletion & Uninstall',
            content:
                'Because all artworks and settings are saved locally, you retain absolute data sovereignty. '
                'You can delete individual artworks, clear cached brush textures, or reset preferences at any time '
                'from Settings → Storage. Uninstalling Draw Color Art Pro permanently deletes all application files '
                'from your device storage.',
          ),

          // ── Section 10: Policy Updates & Contact ──
          const _PolicyCard(
            icon: Icons.update_rounded,
            title: '10. Policy Updates & Contact',
            content:
                'We may update this Privacy Policy from time to time to reflect new app features, updated SDKs, '
                'or evolving legal regulations. Any revisions will be reflected in the application with an updated effective date.',
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

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
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
                  color: theme.colorScheme.primary,
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
