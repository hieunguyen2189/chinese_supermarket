class Product {
  final String id;
  final String hanzi;
  final String pinyin;
  final String icon;
  final String category;
  final int buyPrice;
  final int defaultSellPrice;
  final int minSellPrice;
  final int maxSellPrice;
  final int demand;
  final String measureWord;
  final int unlockDay;

  const Product({
    required this.id,
    required this.hanzi,
    required this.pinyin,
    required this.icon,
    required this.category,
    required this.buyPrice,
    required this.defaultSellPrice,
    required this.minSellPrice,
    required this.maxSellPrice,
    required this.demand,
    required this.measureWord,
    required this.unlockDay,
  });
}