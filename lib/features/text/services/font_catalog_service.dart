import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/font_item.dart';

/// Service managing the library of 100+ curated Google Fonts for styling and artwork typography.
class FontCatalogService {
  FontCatalogService._() {
    _initFonts();
  }

  static final FontCatalogService instance = FontCatalogService._();

  final List<FontItem> _fonts = [];

  List<FontItem> get allFonts => List.unmodifiable(_fonts);
  int get totalCount => _fonts.length;

  void _initFonts() {
    _fonts.clear();

    // ── 1. Modern Sans (20 fonts) ─────────────────────────────────────────────
    _add('Roboto', FontCategory.sansSerif, GoogleFonts.roboto, popular: true);
    _add('Inter', FontCategory.sansSerif, GoogleFonts.inter, popular: true);
    _add('Poppins', FontCategory.sansSerif, GoogleFonts.poppins, popular: true);
    _add('Montserrat', FontCategory.sansSerif, GoogleFonts.montserrat, popular: true);
    _add('Open Sans', FontCategory.sansSerif, GoogleFonts.openSans);
    _add('Lato', FontCategory.sansSerif, GoogleFonts.lato);
    _add('Nunito', FontCategory.sansSerif, GoogleFonts.nunito);
    _add('Raleway', FontCategory.sansSerif, GoogleFonts.raleway);
    _add('Work Sans', FontCategory.sansSerif, GoogleFonts.workSans);
    _add('DM Sans', FontCategory.sansSerif, GoogleFonts.dmSans);
    _add('Plus Jakarta Sans', FontCategory.sansSerif, GoogleFonts.plusJakartaSans);
    _add('Outfit', FontCategory.sansSerif, GoogleFonts.outfit);
    _add('Rubik', FontCategory.sansSerif, GoogleFonts.rubik);
    _add('Jost', FontCategory.sansSerif, GoogleFonts.jost);
    _add('Cabin', FontCategory.sansSerif, GoogleFonts.cabin);
    _add('Quicksand', FontCategory.sansSerif, GoogleFonts.quicksand);
    _add('Heebo', FontCategory.sansSerif, GoogleFonts.heebo);
    _add('Kanit', FontCategory.sansSerif, GoogleFonts.kanit);
    _add('Karla', FontCategory.sansSerif, GoogleFonts.karla);
    _add('Urbanist', FontCategory.sansSerif, GoogleFonts.urbanist);

    // ── 2. Serif & Editorial (18 fonts) ───────────────────────────────────────
    _add('Playfair Display', FontCategory.serif, GoogleFonts.playfairDisplay, popular: true);
    _add('Merriweather', FontCategory.serif, GoogleFonts.merriweather, popular: true);
    _add('Lora', FontCategory.serif, GoogleFonts.lora, popular: true);
    _add('Cinzel', FontCategory.serif, GoogleFonts.cinzel, popular: true);
    _add('Cormorant Garamond', FontCategory.serif, GoogleFonts.cormorantGaramond);
    _add('Bodoni Moda', FontCategory.serif, GoogleFonts.bodoniModa);
    _add('Spectral', FontCategory.serif, GoogleFonts.spectral);
    _add('Prata', FontCategory.serif, GoogleFonts.prata);
    _add('EB Garamond', FontCategory.serif, GoogleFonts.ebGaramond);
    _add('Bitter', FontCategory.serif, GoogleFonts.bitter);
    _add('Arvo', FontCategory.serif, GoogleFonts.arvo);
    _add('Libre Baskerville', FontCategory.serif, GoogleFonts.libreBaskerville);
    _add('Frank Ruhl Libre', FontCategory.serif, GoogleFonts.frankRuhlLibre);
    _add('Castoro', FontCategory.serif, GoogleFonts.castoro);
    _add('Cardo', FontCategory.serif, GoogleFonts.cardo);
    _add('Domine', FontCategory.serif, GoogleFonts.domine);
    _add('Vollkorn', FontCategory.serif, GoogleFonts.vollkorn);
    _add('PT Serif', FontCategory.serif, GoogleFonts.ptSerif);

    // ── 3. Script & Calligraphy (18 fonts) ────────────────────────────────────
    _add('Caveat', FontCategory.script, GoogleFonts.caveat, popular: true);
    _add('Dancing Script', FontCategory.script, GoogleFonts.dancingScript, popular: true);
    _add('Great Vibes', FontCategory.script, GoogleFonts.greatVibes, popular: true);
    _add('Sacramento', FontCategory.script, GoogleFonts.sacramento);
    _add('Alex Brush', FontCategory.script, GoogleFonts.alexBrush);
    _add('Pacifico', FontCategory.script, GoogleFonts.pacifico);
    _add('Parisienne', FontCategory.script, GoogleFonts.parisienne);
    _add('Indie Flower', FontCategory.script, GoogleFonts.indieFlower);
    _add('Shadows Into Light', FontCategory.script, GoogleFonts.shadowsIntoLight);
    _add('Kalam', FontCategory.script, GoogleFonts.kalam);
    _add('Patrick Hand', FontCategory.script, GoogleFonts.patrickHand);
    _add('Yellowtail', FontCategory.script, GoogleFonts.yellowtail);
    _add('Marck Script', FontCategory.script, GoogleFonts.marckScript);
    _add('Bad Script', FontCategory.script, GoogleFonts.badScript);
    _add('Allura', FontCategory.script, GoogleFonts.allura);
    _add('Satisfy', FontCategory.script, GoogleFonts.satisfy);
    _add('Courgette', FontCategory.script, GoogleFonts.courgette);
    _add('Tangerine', FontCategory.script, GoogleFonts.tangerine);

    // ── 4. Display & Bold (18 fonts) ──────────────────────────────────────────
    _add('Bebas Neue', FontCategory.display, GoogleFonts.bebasNeue, popular: true);
    _add('Anton', FontCategory.display, GoogleFonts.anton, popular: true);
    _add('Lobster', FontCategory.display, GoogleFonts.lobster, popular: true);
    _add('Righteous', FontCategory.display, GoogleFonts.righteous);
    _add('Shrikhand', FontCategory.display, GoogleFonts.shrikhand);
    _add('Bangers', FontCategory.display, GoogleFonts.bangers);
    _add('Bungee', FontCategory.display, GoogleFonts.bungee);
    _add('Abril Fatface', FontCategory.display, GoogleFonts.abrilFatface);
    _add('Fredoka', FontCategory.display, GoogleFonts.fredoka);
    _add('Comfortaa', FontCategory.display, GoogleFonts.comfortaa);
    _add('Alfa Slab One', FontCategory.display, GoogleFonts.alfaSlabOne);
    _add('Carter One', FontCategory.display, GoogleFonts.carterOne);
    _add('Titan One', FontCategory.display, GoogleFonts.titanOne);
    _add('Black Ops One', FontCategory.display, GoogleFonts.blackOpsOne);
    _add('Sigmar One', FontCategory.display, GoogleFonts.sigmarOne);
    _add('Fugaz One', FontCategory.display, GoogleFonts.fugazOne);
    _add('Chewy', FontCategory.display, GoogleFonts.chewy);
    _add('Luckiest Guy', FontCategory.display, GoogleFonts.luckiestGuy);

    // ── 5. Futuristic & Sci-Fi (14 fonts) ─────────────────────────────────────
    _add('Orbitron', FontCategory.futuristic, GoogleFonts.orbitron, popular: true);
    _add('Audiowide', FontCategory.futuristic, GoogleFonts.audiowide, popular: true);
    _add('Exo 2', FontCategory.futuristic, GoogleFonts.exo2);
    _add('Rajdhani', FontCategory.futuristic, GoogleFonts.rajdhani);
    _add('Michroma', FontCategory.futuristic, GoogleFonts.michroma);
    _add('Russo One', FontCategory.futuristic, GoogleFonts.russoOne);
    _add('Electrolize', FontCategory.futuristic, GoogleFonts.electrolize);
    _add('Syne', FontCategory.futuristic, GoogleFonts.syne);
    _add('Chakra Petch', FontCategory.futuristic, GoogleFonts.chakraPetch);
    _add('Bruno Ace', FontCategory.futuristic, GoogleFonts.brunoAce);
    _add('Oxanium', FontCategory.futuristic, GoogleFonts.oxanium);
    _add('Nova Square', FontCategory.futuristic, GoogleFonts.novaSquare);
    _add('Megrim', FontCategory.futuristic, GoogleFonts.megrim);
    _add('Monoton', FontCategory.futuristic, GoogleFonts.monoton);

    // ── 6. Vintage & Gothic (10 fonts) ────────────────────────────────────────
    _add('Cinzel Decorative', FontCategory.vintage, GoogleFonts.cinzelDecorative, popular: true);
    _add('MedievalSharp', FontCategory.vintage, GoogleFonts.medievalSharp);
    _add('UnifrakturMaguntia', FontCategory.vintage, GoogleFonts.unifrakturMaguntia);
    _add('Pirata One', FontCategory.vintage, GoogleFonts.pirataOne);
    _add('Rye', FontCategory.vintage, GoogleFonts.rye);
    _add('Sancreek', FontCategory.vintage, GoogleFonts.sancreek);
    _add('Creepster', FontCategory.vintage, GoogleFonts.creepster);
    _add('Metal Mania', FontCategory.vintage, GoogleFonts.metalMania);
    _add('Caesar Dressing', FontCategory.vintage, GoogleFonts.caesarDressing);
    _add('Almendra', FontCategory.vintage, GoogleFonts.almendra);

    // ── 7. Monospace & Code (10 fonts) ────────────────────────────────────────
    _add('Fira Code', FontCategory.monospace, GoogleFonts.firaCode, popular: true);
    _add('JetBrains Mono', FontCategory.monospace, GoogleFonts.jetBrainsMono, popular: true);
    _add('Space Mono', FontCategory.monospace, GoogleFonts.spaceMono);
    _add('Inconsolata', FontCategory.monospace, GoogleFonts.inconsolata);
    _add('Source Code Pro', FontCategory.monospace, GoogleFonts.sourceCodePro);
    _add('VT323', FontCategory.monospace, GoogleFonts.vt323);
    _add('Share Tech Mono', FontCategory.monospace, GoogleFonts.shareTechMono);
    _add('Major Mono Display', FontCategory.monospace, GoogleFonts.majorMonoDisplay);
    _add('Roboto Mono', FontCategory.monospace, GoogleFonts.robotoMono);
    _add('Courier Prime', FontCategory.monospace, GoogleFonts.courierPrime);
  }

  void _add(
    String name,
    FontCategory category,
    TextStyle Function({TextStyle? textStyle}) builder, {
    bool popular = false,
  }) {
    _fonts.add(
      FontItem(
        name: name,
        category: category,
        builder: builder,
        popular: popular,
      ),
    );
  }

  /// Filter fonts by category and search keyword.
  List<FontItem> filter({FontCategory category = FontCategory.all, String? query}) {
    return _fonts.where((font) {
      if (category != FontCategory.all && font.category != category) {
        return false;
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        return font.name.toLowerCase().contains(q) ||
            font.category.label.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  /// Returns the font matching [name] (case-insensitive), or fallback to [defaultFont].
  FontItem getFontByName(String name) {
    return _fonts.firstWhere(
      (f) => f.name.toLowerCase() == name.trim().toLowerCase(),
      orElse: () => defaultFont,
    );
  }

  FontItem get defaultFont => _fonts.firstWhere(
        (f) => f.name == 'Poppins',
        orElse: () => _fonts.first,
      );
}
