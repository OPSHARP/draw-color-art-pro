import 'dart:math';
import '../models/coloring_template.dart';
import 'template_procedural_generator.dart';

class _TemplateDef {
  const _TemplateDef({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.motifIndex,
  });

  final String id;
  final String title;
  final String description;
  final String difficulty;
  final int motifIndex;
}

/// Service managing the library of unique, duplicate-free vector coloring templates.
class ColoringCatalogService {
  ColoringCatalogService._() {
    _initCatalog();
  }

  static final ColoringCatalogService instance = ColoringCatalogService._();

  final List<ColoringTemplate> _templates = [];
  final Set<String> _favoriteIds = {
    'kids_puppy',
    'flowers_sunflower',
    'birds_parrot',
    'mandala_lotus',
    'characters_kitsune',
    'trending_synthwave',
  };

  List<ColoringTemplate> get allTemplates => List.unmodifiable(_templates);
  int get totalCount => _templates.length;
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  bool isFavorite(String id) => _favoriteIds.contains(id);

  bool toggleFavorite(String id) {
    final nowFav = !_favoriteIds.contains(id);
    if (nowFav) {
      _favoriteIds.add(id);
    } else {
      _favoriteIds.remove(id);
    }
    return nowFav;
  }

  static const Map<TemplateCategory, List<_TemplateDef>> _catalogDefinitions = {
    TemplateCategory.mandala: [
      _TemplateDef(
        id: 'mandala_lotus',
        title: 'Sacred Lotus Mandala',
        description: 'Intricate layered concentric lotus petals with center blossom.',
        difficulty: 'Detailed',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'mandala_sunburst',
        title: 'Cosmic Sunburst Yantra',
        description: 'Radiating solar flares and sacred flame rays in balanced harmony.',
        difficulty: 'Medium',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'mandala_harmony_star',
        title: 'Star of Harmony Octagram',
        description: 'Interlaced octagram star geometry with diamond lattice facets.',
        difficulty: 'Detailed',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'mandala_zen_spiral',
        title: 'Zen Spiral Wheel',
        description: 'Hypnotic logarithmic spiral arms and circular boundary waves.',
        difficulty: 'Medium',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'mandala_rose_window',
        title: 'Gothic Rose Window',
        description: 'Cathedral stained-glass inspired radial rosette with gothic trefoils.',
        difficulty: 'Detailed',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'mandala_sri_yantra',
        title: 'Sri Yantra Geometry',
        description: 'Sacred interlocking triangles forming mystical bindu focal points.',
        difficulty: 'Detailed',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'mandala_dreamcatcher',
        title: 'Dreamcatcher Sacred Web',
        description: 'Woven circular willow web with three sacred hanging feathers.',
        difficulty: 'Medium',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'mandala_flower_of_life',
        title: 'Flower of Life',
        description: 'Classical sacred geometry rosette formed by intersecting circular chords.',
        difficulty: 'Detailed',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'mandala_mayan_sun',
        title: 'Mayan Solar Wheel',
        description: 'Ancient solar calendar glyphs with cardinal directional arrows.',
        difficulty: 'Medium',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'mandala_celtic_knot',
        title: 'Celtic Knot Rosette',
        description: 'Interlaced endless 4-fold ribbon knot with concentric borders.',
        difficulty: 'Detailed',
        motifIndex: 9,
      ),
    ],
    TemplateCategory.nature: [
      _TemplateDef(
        id: 'nature_sunflower',
        title: 'Blooming Sunflower',
        description: 'Massive textured seed disk surrounded by double-layered sun petals.',
        difficulty: 'Medium',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'nature_sakura',
        title: 'Cherry Blossom Branch',
        description: 'Graceful woody branch with delicate 5-petal sakura blossoms.',
        difficulty: 'Easy',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'nature_monstera',
        title: 'Tropical Monstera & Palm',
        description: 'Lush perforated split-leaf monstera and arching fan palm fronds.',
        difficulty: 'Medium',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'nature_bonsai',
        title: 'Bonsai Tree on Rock',
        description: 'Gnarled twisting trunk with cloud-like foliage canopies in ceramic pot.',
        difficulty: 'Detailed',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'nature_mushrooms',
        title: 'Forest Mushrooms & Ferns',
        description: 'Spotted woodland toadstools with curling fiddlehead fern fronds.',
        difficulty: 'Easy',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'nature_pine_haven',
        title: 'Mountain Pine Haven',
        description: 'Majestic evergreen conifers framed by snow-capped mountain peaks.',
        difficulty: 'Medium',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'nature_desert_cactus',
        title: 'Desert Saguaro & Dunes',
        description: 'Ribbed desert saguaro with flowering arms and sandy dunes.',
        difficulty: 'Easy',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'nature_water_lily',
        title: 'Floating Water Lily & Pad',
        description: 'Open lotus bloom resting on a notched circular pond lily pad.',
        difficulty: 'Medium',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'nature_autumn_leaves',
        title: 'Autumn Maple & Oak',
        description: 'Detailed vein foliage featuring sugar maple and woodland oak leaves.',
        difficulty: 'Medium',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'nature_classic_rose',
        title: 'Classic Rose in Bloom',
        description: 'Swirling spiral rose blossom with thorny stem and serrated leaves.',
        difficulty: 'Detailed',
        motifIndex: 9,
      ),
    ],
    TemplateCategory.animals: [
      _TemplateDef(
        id: 'animals_lion',
        title: 'Majestic Roaring Lion',
        description: 'Regal lion portrait surrounded by a magnificent flowing radial mane.',
        difficulty: 'Detailed',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'animals_wolf',
        title: 'Royal Timber Wolf',
        description: 'Wolf head howling in profile with full moon and pine trees.',
        difficulty: 'Medium',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'animals_owl',
        title: 'Wise Horned Owl',
        description: 'Perched horned owl with giant concentric feather eyes and patterned chest.',
        difficulty: 'Detailed',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'animals_stag',
        title: 'Graceful Forest Stag',
        description: 'Noble stag with tall branching dendritic antlers and gentle alert eyes.',
        difficulty: 'Detailed',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'animals_fox',
        title: 'Playful Red Fox',
        description: 'Curled sleeping fox with fluffy wrapped tail and pointed ears.',
        difficulty: 'Easy',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'animals_tiger',
        title: 'Royal Bengal Tiger',
        description: 'Fierce frontal tiger face with bold forehead stripes and cheek patterns.',
        difficulty: 'Detailed',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'animals_eagle',
        title: 'Soaring Imperial Eagle',
        description: 'Majestic bird of prey with wide outstretched flight feathers.',
        difficulty: 'Detailed',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'animals_elephant',
        title: 'Gentle Bohemian Elephant',
        description: 'Adorned elephant with raised trunk and ornate decorative headpiece.',
        difficulty: 'Detailed',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'animals_panda',
        title: 'Cozy Panda with Bamboo',
        description: 'Chubby giant panda munching on fresh segmented bamboo stalks.',
        difficulty: 'Easy',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'animals_chameleon',
        title: 'Tropical Chameleon',
        description: 'Perched chameleon on a leafy twig with a curled prehensile spiral tail.',
        difficulty: 'Medium',
        motifIndex: 9,
      ),
    ],
    TemplateCategory.characters: [
      _TemplateDef(
        id: 'characters_stargirl',
        title: 'Chibi Magical Star Girl',
        description: 'Adorable anime girl with starry twin twintails and magic wand.',
        difficulty: 'Medium',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'characters_samurai',
        title: 'Manga Samurai Warrior',
        description: 'Determined warrior with topknot hair, katana sword, and haori coat.',
        difficulty: 'Detailed',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'characters_android',
        title: 'Cyber Hacker Android',
        description: 'Futuristic cyber warrior with holographic visor and glowing collar.',
        difficulty: 'Detailed',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'characters_catgirl',
        title: 'Cute Chibi Catgirl',
        description: 'Sweet anime catgirl with fluffy ears, bell ribbon choker, and wink.',
        difficulty: 'Easy',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'characters_moon_princess',
        title: 'Celestial Moon Princess',
        description: 'Flowing starry hair, crescent tiara, and celestial robes.',
        difficulty: 'Detailed',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'characters_elf_ranger',
        title: 'Forest Elf Ranger',
        description: 'Pointed elf ears, hooded cowl, and elegant recurve bow.',
        difficulty: 'Medium',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'characters_gamer',
        title: 'Retro Chibi Gamer',
        description: 'Cute gamer wearing oversized headset and holding a gamepad.',
        difficulty: 'Easy',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'characters_aviator',
        title: 'Steampunk Aviator',
        description: 'Retro pilot helmet with brass clockwork goggles and flight scarf.',
        difficulty: 'Detailed',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'characters_wizard',
        title: 'Little Wizard Apprentice',
        description: 'Crooked pointy wizard hat, round spectacles, and ancient spellbook.',
        difficulty: 'Medium',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'characters_hero',
        title: 'Chibi Superhero',
        description: 'Heroic domino mask, fluttering dynamic cape, and star emblem.',
        difficulty: 'Easy',
        motifIndex: 9,
      ),
      _TemplateDef(
        id: 'characters_kitsune',
        title: 'Kitsune Fox Spirit Maiden',
        description: 'Mystical anime maiden with traditional fox mask, pointed ears, and flowing tails.',
        difficulty: 'Detailed',
        motifIndex: 10,
      ),
      _TemplateDef(
        id: 'characters_cyberninja',
        title: 'Cyber Ninja Shinobi',
        description: 'Futuristic anime ninja with holographic visor, oversized shuriken, and armored scarf.',
        difficulty: 'Detailed',
        motifIndex: 11,
      ),
      _TemplateDef(
        id: 'characters_saiyan',
        title: 'Shonen Saiyan Energy Hero',
        description: 'Spiky electric anime hair, fiery martial arts aura flames, and fierce battle headband.',
        difficulty: 'Detailed',
        motifIndex: 12,
      ),
      _TemplateDef(
        id: 'characters_mechapilot',
        title: 'Mecha Titan Pilot Hero',
        description: 'High-tech mecha pilot with aerodynamic plugsuit helmet, antenna fins, and glowing core.',
        difficulty: 'Medium',
        motifIndex: 13,
      ),
      _TemplateDef(
        id: 'characters_bobabarista',
        title: 'Kawaii Anime Boba Barista',
        description: 'Adorable anime girl with bear-ear headband, holding a giant milk tea cup with boba pearls.',
        difficulty: 'Easy',
        motifIndex: 14,
      ),
      _TemplateDef(
        id: 'characters_sakurablade',
        title: 'Sakura Blossom Blade Maiden',
        description: 'Graceful samurai maiden with cherry blossom hairpiece, flowing sleeves, and katana.',
        difficulty: 'Detailed',
        motifIndex: 15,
      ),
    ],
    TemplateCategory.space: [
      _TemplateDef(
        id: 'space_saturn',
        title: 'Ringed Saturn & Moonlet',
        description: 'Giant atmospheric planet with multi-lane tilted rings and starry orbit.',
        difficulty: 'Medium',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'space_lunar_lander',
        title: 'Apollo Lunar Lander',
        description: 'Spacecraft module resting on cratered moon surface with distant Earth.',
        difficulty: 'Detailed',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'space_astronaut',
        title: 'Spacewalking Astronaut',
        description: 'Weightless astronaut in bubble helmet exploring the starry void.',
        difficulty: 'Medium',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'space_ufo',
        title: 'Alien Flying Saucer UFO',
        description: 'Retro dome saucer with viewport windows and radiating tractor beam.',
        difficulty: 'Easy',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'space_galaxy',
        title: 'Cosmic Swirling Galaxy',
        description: 'Double-armed spiral galaxy vortex with luminous core and starfields.',
        difficulty: 'Detailed',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'space_crescent_lantern',
        title: 'Crescent Moon & Stars',
        description: 'Whimsical crescent moon with hanging stars and glowing lantern.',
        difficulty: 'Easy',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'space_rocket_launch',
        title: 'Rocket Launch Liftoff',
        description: 'Retro finned rocket blasting into the cosmos on billowing plumes.',
        difficulty: 'Medium',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'space_solar_eclipse',
        title: 'Solar Eclipse Corona',
        description: 'Total solar eclipse surrounded by dramatic magnetic solar flares.',
        difficulty: 'Detailed',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'space_station',
        title: 'Orbital Space Station',
        description: 'Modular space station with rectangular solar panels and antenna.',
        difficulty: 'Detailed',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'space_comet',
        title: 'Blazing Shooting Comet',
        description: 'Icy comet nucleus with streaming double dust trails through stars.',
        difficulty: 'Easy',
        motifIndex: 9,
      ),
    ],
    TemplateCategory.fantasy: [
      _TemplateDef(
        id: 'fantasy_dragon',
        title: 'Fierce Winged Dragon',
        description: 'Mythical dragon head with swept-back horns and curling smoke wisps.',
        difficulty: 'Detailed',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'fantasy_phoenix',
        title: 'Phoenix Rebirth',
        description: 'Legendary bird of fire rising with flaming plumage and ribbon tails.',
        difficulty: 'Detailed',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'fantasy_fairy',
        title: 'Enchanted Fairy on Mushroom',
        description: 'Delicate fairy with dragonfly wings sitting on a forest toadstool.',
        difficulty: 'Medium',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'fantasy_unicorn',
        title: 'Mystical Horned Unicorn',
        description: 'Graceful unicorn profile with spiral alicorn horn and star sparkles.',
        difficulty: 'Medium',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'fantasy_pegasus',
        title: 'Flying Pegasus',
        description: 'Majestic winged stallion soaring with magnificent feathered wings.',
        difficulty: 'Detailed',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'fantasy_potion',
        title: 'Arcane Magic Potion Bottle',
        description: 'Glass alchemy flask with swirling bubbling potion and magic stars.',
        difficulty: 'Easy',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'fantasy_crystal_castle',
        title: 'Crystal Spire Castle',
        description: 'Floating castle towers perched on an enchanted crystal rock island.',
        difficulty: 'Detailed',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'fantasy_gryphon',
        title: 'Gryphon Guardian',
        description: 'Mythical beast combining regal eagle head and noble lion shoulders.',
        difficulty: 'Detailed',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'fantasy_witch_cauldron',
        title: 'Witch Hat & Cauldron',
        description: 'Wide-brim pointed witch hat beside a bubbling iron potion cauldron.',
        difficulty: 'Medium',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'fantasy_sun_moon',
        title: 'Celestial Sun & Moon',
        description: 'Harmonious intertwining of a radiant sun face and serene crescent moon.',
        difficulty: 'Detailed',
        motifIndex: 9,
      ),
    ],
    TemplateCategory.zentangle: [
      _TemplateDef(
        id: 'zentangle_paisley',
        title: 'Paisley Floral Flourish',
        description: 'Curved teardrop paisley filled with intricate petals and dot borders.',
        difficulty: 'Detailed',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'zentangle_metatron',
        title: 'Sacred Metatron Cube',
        description: 'Geometric node matrix forming sacred Platonic solids and circles.',
        difficulty: 'Detailed',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'zentangle_celtic_knot',
        title: 'Woven Celtic Ribbon',
        description: 'Endless interlaced ribbon weave with shaded overlapping crossings.',
        difficulty: 'Detailed',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'zentangle_honeycomb',
        title: 'Honeycomb Hex Matrix',
        description: 'Tessellated hexagonal cells with 3D isometric cube perspectives.',
        difficulty: 'Medium',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'zentangle_optical_wave',
        title: 'Optical Illusion Grid',
        description: 'Undulating warped checkerboard curves creating a 3D illusion.',
        difficulty: 'Detailed',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'zentangle_fish_scales',
        title: 'Flowing Fish Scales',
        description: 'Overlapping scalloped wave rows with fan rays and dot flourishes.',
        difficulty: 'Medium',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'zentangle_baroque',
        title: 'Baroque Filigree Scroll',
        description: 'Royal acanthus leaf scrolls, curling volutes, and heraldic crests.',
        difficulty: 'Detailed',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'zentangle_labyrinth',
        title: 'Labyrinth Maze Mandala',
        description: 'Concentric winding circular maze paths leading to a center sanctuary.',
        difficulty: 'Detailed',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'zentangle_harlequin',
        title: 'Diamond Harlequin Grid',
        description: 'Diagonal diamond prism lattice with alternating optical stripes.',
        difficulty: 'Medium',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'zentangle_vortex',
        title: 'Spiraling Vortex Ribbons',
        description: 'Curving ribbon blades spiraling infinitely into a deep central vortex.',
        difficulty: 'Detailed',
        motifIndex: 9,
      ),
    ],
    TemplateCategory.vehicles: [
      _TemplateDef(
        id: 'vehicles_roadster',
        title: 'Classic 1950s Roadster',
        description: 'Vintage convertible car with chrome grille, rounded fenders, and white-walls.',
        difficulty: 'Medium',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'vehicles_locomotive',
        title: 'Steam Locomotive Train',
        description: 'Heavy steam engine train with cowcatcher, boiler bands, and smoke.',
        difficulty: 'Detailed',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'vehicles_formula_racer',
        title: 'Sleek Formula Racer',
        description: 'Aerodynamic open-wheel racing car with front and rear spoilers.',
        difficulty: 'Medium',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'vehicles_biplane',
        title: 'Twin-Propeller Biplane',
        description: 'Vintage dual-wing biplane with wing struts and front propeller.',
        difficulty: 'Medium',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'vehicles_scooter',
        title: 'Vintage Italian Scooter',
        description: 'Retro motor scooter with curved leg shield and rear luggage rack.',
        difficulty: 'Easy',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'vehicles_galleon',
        title: 'Oceanic Pirate Galleon',
        description: 'Tall wooden ship with billowing square-rigged sails and masts.',
        difficulty: 'Detailed',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'vehicles_hoverbike',
        title: 'Cyberpunk Hoverbike',
        description: 'Futuristic levitation hover vehicle with angular body panels.',
        difficulty: 'Medium',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'vehicles_submarine',
        title: 'Deep Sea Submarine',
        description: 'Yellow research submarine with periscope tower and round portholes.',
        difficulty: 'Easy',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'vehicles_monster_truck',
        title: 'Monster Truck 4x4',
        description: 'Lifted pickup truck body perched atop massive knobby tractor tires.',
        difficulty: 'Medium',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'vehicles_hot_air_balloon',
        title: 'Colorful Hot Air Balloon',
        description: 'Teardrop balloon canopy with vertical gores and wicker passenger basket.',
        difficulty: 'Easy',
        motifIndex: 9,
      ),
    ],
    TemplateCategory.food: [
      _TemplateDef(
        id: 'food_donut',
        title: 'Glazed Sprinkled Donut',
        description: 'Plump ring doughnut with wavy dripping glaze and crunchy sprinkles.',
        difficulty: 'Easy',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'food_birthday_cake',
        title: 'Multi-Tier Celebration Cake',
        description: 'Three-tier frosted party cake with cake stand and birthday candle.',
        difficulty: 'Medium',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'food_ice_cream_sundae',
        title: 'Triple Scoop Sundae',
        description: 'Fluted glass sundae dish with three scoops, wafer stick, and cherry.',
        difficulty: 'Medium',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'food_pizza_slice',
        title: 'Crispy Cheesy Pizza Slice',
        description: 'Triangular slice with melted cheese, pepperoni, and mushrooms.',
        difficulty: 'Easy',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'food_macarons',
        title: 'French Macaron Box',
        description: 'Delicate round sandwich cookies with ruffled feet and cream filling.',
        difficulty: 'Easy',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'food_boba_tea',
        title: 'Kawaii Boba Bubble Tea',
        description: 'Plastic cup with domed lid, thick straw, boba tapioca pearls, and face.',
        difficulty: 'Easy',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'food_pancakes',
        title: 'Stack of Fluffy Pancakes',
        description: 'Four golden flapjacks with melting butter pat and dripping maple syrup.',
        difficulty: 'Easy',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'food_sushi_bento',
        title: 'Japanese Sushi Bento',
        description: 'Wooden board with salmon nigiri, maki sushi rolls, and chopsticks.',
        difficulty: 'Medium',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'food_belgian_waffle',
        title: 'Belgian Waffle & Berries',
        description: 'Crisp square pocketed waffle grid topped with sweet strawberries.',
        difficulty: 'Medium',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'food_cupcake',
        title: 'Sweet Strawberry Cupcake',
        description: 'Fluted baking liner topped with a tall swirl of buttercream and strawberry.',
        difficulty: 'Easy',
        motifIndex: 9,
      ),
    ],
    TemplateCategory.architecture: [
      _TemplateDef(
        id: 'architecture_pagoda',
        title: 'Japanese Pagoda Sanctuary',
        description: 'Traditional 3-tiered wooden pagoda with curved eaves and finial.',
        difficulty: 'Detailed',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'architecture_cathedral',
        title: 'Gothic Cathedral Facade',
        description: 'Twin soaring bell towers, circular rose window, and pointed portals.',
        difficulty: 'Detailed',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'architecture_castle',
        title: 'Fairy Tale Castle',
        description: 'Crenellated stone ramparts, conical turret roofs, and drawbridge.',
        difficulty: 'Medium',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'architecture_windmill',
        title: 'Dutch Windmill in Tulips',
        description: 'Octagonal timber windmill with four lattice sails flanked by tulips.',
        difficulty: 'Medium',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'architecture_parthenon',
        title: 'Ancient Greek Parthenon',
        description: 'Classical temple with stepped stylobate and fluted Doric columns.',
        difficulty: 'Detailed',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'architecture_skyscraper',
        title: 'Modern Skyline Skyscraper',
        description: 'Contemporary glass tower skyline with setback terraces and spire.',
        difficulty: 'Medium',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'architecture_log_cabin',
        title: 'Cozy Alpine Log Cabin',
        description: 'A-frame wooden cabin with stone chimney smoke and snowy porch.',
        difficulty: 'Medium',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'architecture_eiffel_tower',
        title: 'Parisian Eiffel Tower',
        description: 'Iconic wrought-iron lattice spire with viewing platforms and arches.',
        difficulty: 'Detailed',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'architecture_taj_mahal',
        title: 'Taj Mahal Dome Silhouette',
        description: 'Monumental onion dome, grand iwan arches, and slender minarets.',
        difficulty: 'Detailed',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'architecture_venice_bridge',
        title: 'Venetian Canal Bridge',
        description: 'Curving stone footbridge spanning water with gondola silhouette.',
        difficulty: 'Medium',
        motifIndex: 9,
      ),
    ],
    TemplateCategory.ocean: [
      _TemplateDef(
        id: 'ocean_dolphin',
        title: 'Leaping Ocean Dolphin',
        description: 'Sleek bottlenose dolphin breaching in an arch over cresting waves.',
        difficulty: 'Easy',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'ocean_sea_turtle',
        title: 'Sea Turtle in Coral Reef',
        description: 'Graceful sea turtle with patterned shell swimming past coral reefs.',
        difficulty: 'Medium',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'ocean_humpback_whale',
        title: 'Majestic Humpback Whale',
        description: 'Enormous whale breaching with grooved throat pleats and tail fluke.',
        difficulty: 'Medium',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'ocean_seahorse',
        title: 'Graceful Seahorse',
        description: 'Coroneted seahorse with armored ring plates clinging to kelp grass.',
        difficulty: 'Medium',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'ocean_clownfish',
        title: 'Tropical Clownfish & Anemone',
        description: 'Banded clownfish swimming nestled among wavy sea anemone tentacles.',
        difficulty: 'Easy',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'ocean_clownfish_kraken',
        title: 'Giant Kraken Octopus',
        description: 'Intelligent domed octopus head with eight coiling suction tentacles.',
        difficulty: 'Detailed',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'ocean_manta_ray',
        title: 'Manta Ray Glider',
        description: 'Wide diamond wing fins gliding through deep blue ocean currents.',
        difficulty: 'Medium',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'ocean_jellyfish',
        title: 'Luminescent Jellyfish',
        description: 'Translucent umbrella bell dome with trailing oral arms and stinger trails.',
        difficulty: 'Medium',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'ocean_pearl_shell',
        title: 'Scallop Pearl Shell',
        description: 'Open ribbed clamshell revealing a shining spherical pearl inside.',
        difficulty: 'Easy',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'ocean_hammerhead',
        title: 'Hammerhead Shark',
        description: 'Distinctive wide cephalofoil hammerhead shark cruising through waters.',
        difficulty: 'Medium',
        motifIndex: 9,
      ),
    ],
    TemplateCategory.abstractArt: [
      _TemplateDef(
        id: 'abstract_hex_crystal',
        title: 'Prismatic Hexagon Crystal',
        description: 'Interlocking isometric hexagonal cubes creating an optical illusion.',
        difficulty: 'Medium',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'abstract_bauhaus',
        title: 'Bauhaus Constructivist Balance',
        description: 'Bold intersecting circles, diagonal balance bars, and geometric grid.',
        difficulty: 'Medium',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'abstract_memphis',
        title: 'Memphis Geometric Pop Art',
        description: 'Playful 1980s squiggles, zigzag chevrons, floating triangles, and dots.',
        difficulty: 'Easy',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'abstract_mid_century',
        title: 'Mid-Century Modern Organic',
        description: 'Retro atomic pebble shapes, boomerang curves, and starburst crosses.',
        difficulty: 'Easy',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'abstract_optical_vortex',
        title: 'Kinetic Optical Vortex',
        description: 'Radiating curved fan blades creating a hypnotic rotating optical vortex.',
        difficulty: 'Detailed',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'abstract_golden_ratio',
        title: 'Sacred Golden Ratio Chords',
        description: 'Intersecting circular arcs and harmonic geometric chords dividing space.',
        difficulty: 'Detailed',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'abstract_triangle_facets',
        title: 'Dynamic Triangle Facets',
        description: 'Low-poly fractured crystal surface forming a 3D faceted terrain.',
        difficulty: 'Medium',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'abstract_liquid_ripple',
        title: 'Liquid Waveform Ripple',
        description: 'Topographic contour elevation lines rippling outward like liquid drops.',
        difficulty: 'Medium',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'abstract_stained_glass',
        title: 'Stained Glass Polygon Mosaic',
        description: 'Radiating web of angular geometric shards resembling leaded glass.',
        difficulty: 'Detailed',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'abstract_synthwave_grid',
        title: 'Retro Synthwave Horizon Grid',
        description: 'Perspective wireframe road receding toward a giant retro sun.',
        difficulty: 'Medium',
        motifIndex: 9,
      ),
    ],
    TemplateCategory.kids: [
      _TemplateDef(
        id: 'kids_teddy_bear',
        title: 'Teddy Bear Joy',
        description: 'Cute rounded teddy bear with stitched belly patch, sweet nose, and paws.',
        difficulty: 'Easy',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'kids_dinosaur',
        title: 'Playful Dinosaur',
        description: 'Friendly cartoon dinosaur with back plates and happy smile.',
        difficulty: 'Easy',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'kids_sunshine',
        title: 'Smiley Sunshine & Clouds',
        description: 'Smiling sun with friendly eyes and rays nestled among puffy clouds.',
        difficulty: 'Easy',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'kids_rocket',
        title: 'Friendly Rocket & Stars',
        description: 'Cute cartoon rocket ship with round porthole, fins, and twinkle stars.',
        difficulty: 'Easy',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'kids_kitty',
        title: 'Sweet Kitty Cat',
        description: 'Chibi kitten with pointy ears, whiskers, curled paws, and sweet smile.',
        difficulty: 'Easy',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'kids_ice_cream',
        title: 'Ice Cream Sundae Cone',
        description: 'Waffle cone stacked with three scoops of ice cream and cherry on top.',
        difficulty: 'Easy',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'kids_cartoon_car',
        title: 'Chubby Cartoon Car',
        description: 'Friendly bubbly car with big round wheels and smiley headlight.',
        difficulty: 'Easy',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'kids_robot',
        title: 'Friendly Robot Buddy',
        description: 'Square robot with antenna, glowing eye dials, and chest meter.',
        difficulty: 'Easy',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'kids_sea_turtle',
        title: 'Swimming Baby Turtle',
        description: 'Adorable cartoon sea turtle paddling along with gentle smile.',
        difficulty: 'Easy',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'kids_butterfly',
        title: 'Fluttering Butterfly',
        description: 'Cute butterfly with curly antennae, smiley face, and round-spotted wings.',
        difficulty: 'Easy',
        motifIndex: 9,
      ),
      _TemplateDef(
        id: 'kids_puppy',
        title: 'Cute Playful Puppy',
        description: 'Happy puppy with floppy ears, wagging tail, and sweet snout.',
        difficulty: 'Easy',
        motifIndex: 10,
      ),
      _TemplateDef(
        id: 'kids_bunny',
        title: 'Fluffy Bunny in Garden',
        description: 'Adorable rabbit with tall ears, cute whiskers, and round paws.',
        difficulty: 'Easy',
        motifIndex: 11,
      ),
      _TemplateDef(
        id: 'kids_baby_elephant',
        title: 'Gentle Baby Elephant',
        description: 'Little elephant with large floppy ears, curling trunk, and water bubbles.',
        difficulty: 'Easy',
        motifIndex: 12,
      ),
      _TemplateDef(
        id: 'kids_kitten',
        title: 'Little Curious Kitten',
        description: 'Playful kitten with pointy triangle ears, collar bell, and curling tail.',
        difficulty: 'Easy',
        motifIndex: 13,
      ),
      _TemplateDef(
        id: 'kids_giraffe',
        title: 'Smiling Baby Giraffe',
        description: 'Friendly tall-necked giraffe with cute horns and decorative spot patches.',
        difficulty: 'Easy',
        motifIndex: 14,
      ),
      _TemplateDef(
        id: 'kids_koala',
        title: 'Sweet Koala on Branch',
        description: 'Fluffy round-eared koala hugging a tree branch with eucalyptus leaves.',
        difficulty: 'Easy',
        motifIndex: 15,
      ),
      _TemplateDef(
        id: 'kids_monkey',
        title: 'Cheeky Little Monkey',
        description: 'Happy cartoon monkey with curly spiral tail holding a yellow banana.',
        difficulty: 'Easy',
        motifIndex: 16,
      ),
      _TemplateDef(
        id: 'kids_lion_cub',
        title: 'Brave Lion Cub',
        description: 'Sunny little lion cub with flower-petal mane and sweet cheerful face.',
        difficulty: 'Easy',
        motifIndex: 17,
      ),
      _TemplateDef(
        id: 'kids_hedgehog',
        title: 'Happy Spiky Hedgehog',
        description: 'Curled hedgehog with radiating friendly spines and pointy cute nose.',
        difficulty: 'Easy',
        motifIndex: 18,
      ),
      _TemplateDef(
        id: 'kids_kangaroo',
        title: 'Hopping Joey Kangaroo',
        description: 'Loving mama kangaroo with baby joey peeking from cozy front pouch.',
        difficulty: 'Easy',
        motifIndex: 19,
      ),
      _TemplateDef(
        id: 'kids_lamb',
        title: 'Gentle Woolly Lamb',
        description: 'Fluffy cloud-like sheep with droopy ears and sweet gentle smile.',
        difficulty: 'Easy',
        motifIndex: 20,
      ),
      _TemplateDef(
        id: 'kids_otter',
        title: 'Playful River Otter',
        description: 'Cute river otter floating on tummy over peaceful water ripples.',
        difficulty: 'Easy',
        motifIndex: 21,
      ),
      _TemplateDef(
        id: 'kids_hippo',
        title: 'Splashy Baby Hippo',
        description: 'Chubby little hippo with big snout and nostrils splashing in river.',
        difficulty: 'Easy',
        motifIndex: 22,
      ),
      _TemplateDef(
        id: 'kids_zebra',
        title: 'Striped Little Zebra',
        description: 'Friendly cartoon zebra with spiky upright mane and bold safari stripes.',
        difficulty: 'Easy',
        motifIndex: 23,
      ),
      _TemplateDef(
        id: 'kids_fawn',
        title: 'Forest Baby Fawn',
        description: 'Gentle little deer resting with big soft eyes and sweet back spots.',
        difficulty: 'Easy',
        motifIndex: 24,
      ),
      _TemplateDef(
        id: 'kids_hamster',
        title: 'Nibbling Tiny Hamster',
        description: 'Plump round hamster with puffed cheeks holding a giant sunflower seed.',
        difficulty: 'Easy',
        motifIndex: 25,
      ),
      _TemplateDef(
        id: 'kids_piglet',
        title: 'Muddy Happy Piglet',
        description: 'Cheerful round piglet with oval snout, folded ears, and curly corkscrew tail.',
        difficulty: 'Easy',
        motifIndex: 26,
      ),
      _TemplateDef(
        id: 'kids_sloth',
        title: 'Cozy Sloth on Branch',
        description: 'Peaceful sleepy sloth hanging upside down from a jungle tree branch.',
        difficulty: 'Easy',
        motifIndex: 27,
      ),
    ],
    TemplateCategory.birds: [
      _TemplateDef(
        id: 'birds_parrot',
        title: 'Tropical Macaw Parrot',
        description: 'Exotic parrot perched on a jungle branch with layered tail feathers.',
        difficulty: 'Easy',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'birds_flamingo',
        title: 'Elegant Pink Flamingo',
        description: 'Graceful long-necked flamingo standing on one leg among pond ripples.',
        difficulty: 'Easy',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'birds_barn_owl',
        title: 'Wise Little Barn Owl',
        description: 'Charming nocturnal owl with heart facial disc and big round eyes.',
        difficulty: 'Medium',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'birds_penguin',
        title: 'Chubby Arctic Penguin',
        description: 'Adorable cartoon penguin standing proudly on an arctic ice shelf.',
        difficulty: 'Easy',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'birds_toucan',
        title: 'Rainbow Toucan',
        description: 'Rainforest toucan with giant striped bill resting on lush foliage.',
        difficulty: 'Easy',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'birds_hummingbird',
        title: 'Darting Hummingbird',
        description: 'Tiny iridescent hummingbird hovering to sip nectar from a flower.',
        difficulty: 'Medium',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'birds_peacock',
        title: 'Majestic Crown Peacock',
        description: 'Proud peacock spreading a magnificent fan of eye-spotted tail plumes.',
        difficulty: 'Detailed',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'birds_duckling',
        title: 'Puddle Duckling',
        description: 'Sweet baby duck swimming merrily across calm water ripples.',
        difficulty: 'Easy',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'birds_swan',
        title: 'Graceful Lake Swan',
        description: 'Royal swan with arched neck and wings gliding across lake reflections.',
        difficulty: 'Easy',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'birds_rooster',
        title: 'Morning Rooster',
        description: 'Proud farm rooster crowing at sunrise with tall comb and sickle tail.',
        difficulty: 'Medium',
        motifIndex: 9,
      ),
      _TemplateDef(
        id: 'birds_seagull',
        title: 'Coastal Flying Seagull',
        description: 'Seagull soaring freely with outstretched wings over ocean waves.',
        difficulty: 'Easy',
        motifIndex: 10,
      ),
      _TemplateDef(
        id: 'birds_blue_jay',
        title: 'Blue Crested Jay',
        description: 'Smart crested woodland jay perched beside evergreen pinecones.',
        difficulty: 'Medium',
        motifIndex: 11,
      ),
      _TemplateDef(
        id: 'birds_robin',
        title: 'Spring Song Robin',
        description: 'Plump cheerful garden robin singing with musical notes on twig.',
        difficulty: 'Easy',
        motifIndex: 12,
      ),
      _TemplateDef(
        id: 'birds_chick',
        title: 'Tiny Spring Chick',
        description: 'Newborn fluffy chick peeking out from a cracked eggshell.',
        difficulty: 'Easy',
        motifIndex: 13,
      ),
      _TemplateDef(
        id: 'birds_cockatoo',
        title: 'Crested Cockatoo',
        description: 'Tropical white cockatoo with dramatic fanned yellow crest feathers.',
        difficulty: 'Medium',
        motifIndex: 14,
      ),
      _TemplateDef(
        id: 'birds_woodpecker',
        title: 'Forest Woodpecker',
        description: 'Hardworking woodpecker clinging vertically to a forest tree trunk.',
        difficulty: 'Medium',
        motifIndex: 15,
      ),
      _TemplateDef(
        id: 'birds_dove',
        title: 'Peaceful White Dove',
        description: 'Gentle peace dove in flight carrying a fresh green olive branch.',
        difficulty: 'Easy',
        motifIndex: 16,
      ),
      _TemplateDef(
        id: 'birds_sparrow',
        title: 'Garden Song Sparrow',
        description: 'Sweet round sparrow with patterned wing feathers perched outdoors.',
        difficulty: 'Easy',
        motifIndex: 17,
      ),
    ],
    TemplateCategory.flowers: [
      _TemplateDef(
        id: 'flowers_sunflower',
        title: 'Giant Golden Sunflower',
        description: 'Vibrant sun-loving bloom with radiating petals, broad leaves, and seed center.',
        difficulty: 'Easy',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'flowers_tulips',
        title: 'Spring Dutch Tulips',
        description: 'Cluster of three classic cup-shaped tulip blossoms with arched foliage.',
        difficulty: 'Easy',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'flowers_daisy',
        title: 'Field Daisy Meadow',
        description: 'Cheerful wild daisy with radiating petals and slender garden leaves.',
        difficulty: 'Easy',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'flowers_sakura',
        title: 'Spring Sakura Bloom',
        description: 'Delicate Japanese cherry blossoms and buds blooming along a bonsai branch.',
        difficulty: 'Medium',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'flowers_rose',
        title: 'Classic Blooming Rose',
        description: 'Velvety spiraling rose petals unfurling above a leafy thorny stem.',
        difficulty: 'Medium',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'flowers_lotus',
        title: 'Serene Sacred Lotus',
        description: 'Spiritual water lily floating gracefully above a wide circular lily pad.',
        difficulty: 'Easy',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'flowers_hibiscus',
        title: 'Tropical Hibiscus Bloom',
        description: 'Five broad ruffled island petals with an exotic arched pollen column.',
        difficulty: 'Easy',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'flowers_marigold',
        title: 'Radiant Aztec Marigold',
        description: 'Dense ruffled golden pom-pom bloom surrounded by decorative foliage.',
        difficulty: 'Medium',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'flowers_daffodil',
        title: 'Golden Spring Daffodil',
        description: 'Star-shaped perianth petals with a ruffled flared central trumpet cup.',
        difficulty: 'Easy',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'flowers_orchid',
        title: 'Exotic Regal Orchid',
        description: 'Graceful cascading orchid stem with three exotic sculptural blossoms.',
        difficulty: 'Detailed',
        motifIndex: 9,
      ),
      _TemplateDef(
        id: 'flowers_bluebells',
        title: 'Woodland Wild Bluebells',
        description: 'Arched nodding woodland stem with drooping bell-shaped wildflower cups.',
        difficulty: 'Easy',
        motifIndex: 10,
      ),
      _TemplateDef(
        id: 'flowers_carnation',
        title: 'Ruffled Carnation',
        description: 'Multi-tiered ruffled petals creating a dense fluffy celebratory flower.',
        difficulty: 'Medium',
        motifIndex: 11,
      ),
      _TemplateDef(
        id: 'flowers_poppy',
        title: 'Wild Scarlet Poppy',
        description: 'Four delicate papery petals framing a round seed pod and nodding bud.',
        difficulty: 'Easy',
        motifIndex: 12,
      ),
      _TemplateDef(
        id: 'flowers_calla_lily',
        title: 'Graceful Calla Lily',
        description: 'Minimalist elegant curved spathe funnel with central golden spadix.',
        difficulty: 'Easy',
        motifIndex: 13,
      ),
      _TemplateDef(
        id: 'flowers_lavender',
        title: 'Fragrant Lavender Sprigs',
        description: 'Aromatic bundle of purple floral florets tied with a delicate ribbon bow.',
        difficulty: 'Easy',
        motifIndex: 14,
      ),
      _TemplateDef(
        id: 'flowers_succulent',
        title: 'Desert Echeveria Succulent',
        description: 'Geometric rosette of fleshy rounded leaves potted in a terracotta planter.',
        difficulty: 'Medium',
        motifIndex: 15,
      ),
      _TemplateDef(
        id: 'flowers_dandelion',
        title: 'Wished Dandelion Bloom',
        description: 'Golden dandelion bloom beside a fluffy clock with seeds floating in the breeze.',
        difficulty: 'Easy',
        motifIndex: 16,
      ),
      _TemplateDef(
        id: 'flowers_peony',
        title: 'Lush Spring Peony',
        description: 'Luxurious giant garden bloom with layered romantic ruffled petals.',
        difficulty: 'Detailed',
        motifIndex: 17,
      ),
    ],
    TemplateCategory.trendingArt: [
      _TemplateDef(
        id: 'trending_synthwave',
        title: 'Synthwave 80s Sunset Grid',
        description: 'Retro futuristic neon sun over an infinite perspective highway grid with palm silhouettes.',
        difficulty: 'Medium',
        motifIndex: 0,
      ),
      _TemplateDef(
        id: 'trending_cyberpunk',
        title: 'Cyberpunk Neon Cityscape',
        description: 'Towering futuristic skyscrapers with digital antenna spires and a zooming flying spinner car.',
        difficulty: 'Detailed',
        motifIndex: 1,
      ),
      _TemplateDef(
        id: 'trending_vaporwave',
        title: 'Vaporwave Classical Aesthetic',
        description: 'Classical Greek sculpture bust outline with glitch visor, wireframe pyramids, and tropical vibes.',
        difficulty: 'Detailed',
        motifIndex: 2,
      ),
      _TemplateDef(
        id: 'trending_boba',
        title: 'Kawaii Aesthetic Boba Cup',
        description: 'Trendy iced milk tea cup with kawaii smiling face, striped straw, heart ice cubes, and tapioca pearls.',
        difficulty: 'Easy',
        motifIndex: 3,
      ),
      _TemplateDef(
        id: 'trending_origami_fox',
        title: 'Low-Poly Geometric Origami Fox',
        description: 'Clean modern faceted origami polygons forming a magnificent sitting woodland fox.',
        difficulty: 'Detailed',
        motifIndex: 4,
      ),
      _TemplateDef(
        id: 'trending_cassette',
        title: 'Retro Cassette & DJ Headphones',
        description: 'Nostalgic 80s magnetic tape cassette with oversized studio headphones and musical note accents.',
        difficulty: 'Medium',
        motifIndex: 5,
      ),
      _TemplateDef(
        id: 'trending_graffiti_crown',
        title: 'Street Graffiti Winged Crown',
        description: 'Urban royal crown with spray paint drips, spreading angel wings, and diamond starbursts.',
        difficulty: 'Detailed',
        motifIndex: 6,
      ),
      _TemplateDef(
        id: 'trending_dreamcatcher',
        title: 'Cosmic Sacred Dreamcatcher',
        description: 'Intricate woven web mandala hoop with beaded hanging quills, feathers, and crescent moon.',
        difficulty: 'Detailed',
        motifIndex: 7,
      ),
      _TemplateDef(
        id: 'trending_popart_boom',
        title: 'Pop Art Comic Boom Explosion',
        description: 'Iconic Lichtenstein vintage comic book starburst with 3D BOOM lettering and speed lines.',
        difficulty: 'Easy',
        motifIndex: 8,
      ),
      _TemplateDef(
        id: 'trending_cyber_skull',
        title: 'Cybernetic Circuit Skull',
        description: 'Modern cyber-aesthetic skull adorned with printed circuit board tracks, cyber aperture, and halo.',
        difficulty: 'Detailed',
        motifIndex: 9,
      ),
    ],
  };

  void _initCatalog() {
    _templates.clear();

    for (final category in TemplateCategory.values) {
      final defs = _catalogDefinitions[category] ?? [];

      for (int i = 0; i < defs.length; i++) {
        final def = defs[i];
        final seed = category.index * 100 + i;

        _templates.add(
          ColoringTemplate(
            id: def.id,
            title: def.title,
            category: category.label,
            description: def.description,
            icon: category.icon,
            gradient: category.gradient,
            difficulty: def.difficulty,
            seed: seed,
            strokeGenerator: (w, h) => TemplateProceduralGenerator.generate(
              seed,
              category,
              w,
              h,
              motifIndex: def.motifIndex,
            ),
          ),
        );
      }
    }
  }

  /// Returns a completely random template from the catalog.
  ColoringTemplate getRandomTemplate() {
    if (_templates.isEmpty) _initCatalog();
    final rng = Random();
    return _templates[rng.nextInt(_templates.length)];
  }

  /// Filters templates by category, difficulty, query, and favorites.
  List<ColoringTemplate> filter({
    String? categoryLabel,
    String? difficulty,
    String? query,
    bool onlyFavorites = false,
  }) {
    if (_templates.isEmpty) _initCatalog();

    return _templates.where((t) {
      if (onlyFavorites && !_favoriteIds.contains(t.id)) {
        return false;
      }
      if (categoryLabel != null && categoryLabel != 'All' && t.category != categoryLabel) {
        return false;
      }
      if (difficulty != null && difficulty != 'All' && t.difficulty != difficulty) {
        return false;
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchesTitle = t.title.toLowerCase().contains(q);
        final matchesCat = t.category.toLowerCase().contains(q);
        final matchesDesc = t.description.toLowerCase().contains(q);
        if (!matchesTitle && !matchesCat && !matchesDesc) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Returns a curated, high-diversity list of featured coloring templates across all categories,
  /// prominently showcasing Kids animals, Birds, Flowers, Mandalas, Nature, and Animals for home screen previews.
  List<ColoringTemplate> getFeaturedTemplates() {
    if (_templates.isEmpty) _initCatalog();

    const featuredIds = [
      'kids_puppy',
      'birds_parrot',
      'flowers_sunflower',
      'kids_bunny',
      'birds_flamingo',
      'flowers_tulips',
      'kids_baby_elephant',
      'birds_barn_owl',
      'flowers_sakura',
      'kids_kitten',
      'birds_toucan',
      'flowers_rose',
      'kids_lion_cub',
      'birds_hummingbird',
      'flowers_lotus',
      'kids_koala',
      'birds_peacock',
      'flowers_hibiscus',
      'mandala_lotus',
      'animals_tiger',
      'nature_forest_deer',
      'ocean_dolphin',
      'space_galaxy',
      'fantasy_dragon',
    ];

    final featured = <ColoringTemplate>[];
    for (final id in featuredIds) {
      final match = _templates.where((t) => t.id == id).firstOrNull;
      if (match != null) {
        featured.add(match);
      }
    }

    if (featured.isNotEmpty) return featured;
    return _templates.take(20).toList();
  }
}
