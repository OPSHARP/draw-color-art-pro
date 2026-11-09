import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob service managing responsive, non-intrusive production ads.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// AdMob IDs configured safely via compile-time environment variables.
  /// Defaults to official Google Mobile Ads test IDs for public repository safety.
  static const String liveAppId = String.fromEnvironment(
    'ADMOB_APP_ID',
    defaultValue: 'ca-app-pub-3940256099942544~3347511713',
  );
  static const String liveBannerAdUnitId = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  );
  static const String liveInterstitialAdUnitId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );
  static const String liveAppOpenAdUnitId = String.fromEnvironment(
    'ADMOB_APP_OPEN_ID',
    defaultValue: 'ca-app-pub-3940256099942544/9257390708',
  );

  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    return liveBannerAdUnitId;
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    return liveInterstitialAdUnitId;
  }

  static String get appOpenAdUnitId {
    if (kIsWeb) return '';
    return liveAppOpenAdUnitId;
  }

  /// Initialize MobileAds SDK
  Future<void> init() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      loadInterstitialAd();
      loadAppOpenAd();
    } catch (e) {
      debugPrint('AdService: MobileAds initialization error: $e');
    }
  }

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  DateTime? _lastInterstitialShowTime;
  static const Duration _interstitialCooldown = Duration(minutes: 6);

  /// Preload an interstitial ad
  void loadInterstitialAd() {
    if (!_initialized || _isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _interstitialAd = null;
            },
          );
        },
        onAdFailedToLoad: (err) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
          debugPrint('AdService: Interstitial failed to load: $err');
        },
      ),
    );
  }

  /// Show interstitial ad with strict cooldown to ensure the user is NEVER irritated
  void showInterstitialAd({bool force = false}) {
    if (_interstitialAd == null) {
      loadInterstitialAd();
      return;
    }

    // Enforce 6-minute cooldown between interstitials to avoid user irritation
    if (!force && _lastInterstitialShowTime != null) {
      if (DateTime.now().difference(_lastInterstitialShowTime!) < _interstitialCooldown) {
        return;
      }
    }

    _lastInterstitialShowTime = DateTime.now();
    _interstitialAd!.show();
  }

  AppOpenAd? _appOpenAd;
  bool _isAppOpenLoading = false;
  DateTime? _appOpenLoadTime;
  DateTime? _lastAppOpenShowTime;
  static const Duration _appOpenCooldown = Duration(minutes: 5);

  /// Preload an App Open ad
  void loadAppOpenAd() {
    if (!_initialized || _isAppOpenLoading || _appOpenAd != null) return;
    _isAppOpenLoading = true;

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenLoading = false;
          _appOpenLoadTime = DateTime.now();
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _appOpenAd = null;
              loadAppOpenAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _appOpenAd = null;
            },
          );
        },
        onAdFailedToLoad: (err) {
          _isAppOpenLoading = false;
          _appOpenAd = null;
          debugPrint('AdService: App Open ad failed to load: $err');
        },
      ),
    );
  }

  /// Show App Open ad if available, fresh (< 4 hours), and respecting frequency cooldown
  void showAppOpenAdIfAvailable() {
    if (_appOpenAd == null) {
      loadAppOpenAd();
      return;
    }
    final loadTime = _appOpenLoadTime;
    if (loadTime != null && DateTime.now().difference(loadTime).inHours >= 4) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      loadAppOpenAd();
      return;
    }

    // Enforce 5-minute cooldown on App Open ads
    if (_lastAppOpenShowTime != null &&
        DateTime.now().difference(_lastAppOpenShowTime!) < _appOpenCooldown) {
      return;
    }

    _lastAppOpenShowTime = DateTime.now();
    _appOpenAd?.show();
  }
}

/// Fully responsive, non-intrusive AdMob Banner Widget.
///
/// Automatically computes anchored adaptive banner sizes matching the device width,
/// avoiding horizontal overflows and never blocking drawing tools.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key, this.adSize});

  final AdSize? adSize;

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  AdSize? _resolvedSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) {
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (AdService.bannerAdUnitId.isEmpty) return;

    final double screenWidth = MediaQuery.sizeOf(context).width;
    final int width = (screenWidth - 32).truncate().clamp(280, 728);

    // Compute responsive Anchored Adaptive Banner size
    AdSize targetSize = widget.adSize ?? AdSize.banner;
    try {
      final adaptiveSize = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (adaptiveSize != null) {
        targetSize = adaptiveSize;
      }
    } catch (_) {}

    if (!mounted) return;
    _resolvedSize = targetSize;

    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: targetSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdBannerWidget: Failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _bannerAd = null;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null || _resolvedSize == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isLoaded ? 1.0 : 0.0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF6F6F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C40) : const Color(0xFFE5E5EA),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Discreet sponsor indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    margin: const EdgeInsets.only(bottom: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2E2E44) : const Color(0xFFE2E2EA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SPONSORED',
                      style: TextStyle(
                        fontSize: 8.5,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),
                ],
              ),
              // Responsive Banner Ad
              SizedBox(
                width: _resolvedSize!.width.toDouble(),
                height: _resolvedSize!.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
