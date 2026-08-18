enum BauCuaFace {
  bau('bau', 'Bau'),
  cua('cua', 'Cua'),
  tom('tom', 'Tom'),
  ca('ca', 'Ca'),
  ga('ga', 'Ga'),
  nai('nai', 'Nai');

  const BauCuaFace(this.assetName, this.label);

  final String assetName;
  final String label;

  String get symbolAsset => 'assets/symbol_$assetName.png';
  String get diceAsset => 'assets/dice_$assetName.png';
}
