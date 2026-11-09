/// Drawing tool types available in the toolbar.
enum DrawingTool {
  brush('Brush', 'B'),
  pencil('Pencil', 'P'),
  pen('Pen', null),
  marker('Marker', null),
  fill('Fill', 'G'),
  eraser('Eraser', 'E'),
  eyedropper('Eyedropper', 'I'),
  selection('Selection', 'S'),
  transform('Transform', 'M'),
  shape('Shape', null),
  text('Text & Fonts', 'T'),
  image('Photo / Image', 'V'),
  smudge('Smudge', null),
  blur('Blur', null),
  glow('Glow Neon', null),
  spray('Airbrush', null),
  symmetry('Symmetry', null),
  ruler('Ruler Guide', null),
  calligraphy('Calligraphy', null),
  crayon('Crayon & Pastel', null),
  dotted('Dotted Pen', null),
  patternStamp('Pattern Stamp', null),
  pixel('Pixel Brush', null),
  highlighter('Highlighter', 'H'),
  rainbow('Rainbow Brush', null),
  gradient('Gradient Fill', null);

  const DrawingTool(this.label, this.shortcutKey);
  final String label;
  final String? shortcutKey;
}

/// Selection tool types.
enum SelectionTool {
  rectangle('Rectangle'),
  ellipse('Ellipse'),
  freehand('Freehand Lasso'),
  polygon('Polygon'),
  magicWand('Magic Wand'),
  colorSelect('Color Selection');

  const SelectionTool(this.label);
  final String label;
}

/// Shape tool types.
enum ShapeTool {
  line('Line'),
  rectangle('Rectangle'),
  roundedRectangle('Rounded Rectangle'),
  circle('Circle'),
  ellipse('Ellipse'),
  triangle('Triangle'),
  polygon('Polygon'),
  star('Star'),
  heart('Heart'),
  hexagon('Hexagon'),
  arrow('Arrow'),
  // New shapes
  pentagon('Pentagon'),
  octagon('Octagon'),
  diamond('Diamond'),
  cross('Cross'),
  ring('Ring / Donut'),
  crescent('Crescent'),
  chevron('Chevron'),
  speechBubble('Speech Bubble'),
  banner('Banner / Ribbon'),
  starburst('Starburst'),
  shield('Shield / Badge'),
  playButton('Play Button'),
  musicNote('Music Note'),
  crown('Crown');

  const ShapeTool(this.label);
  final String label;
}

/// Save status indicator states.
enum SaveStatus {
  saved('Saved'),
  saving('Saving...'),
  offline('Offline'),
  syncing('Syncing'),
  error('Sync Error');

  const SaveStatus(this.label);
  final String label;
}
