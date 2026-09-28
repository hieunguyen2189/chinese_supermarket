class GameState {
  int money;
  int reputation;
  int day;

  Map<String, int> inventory;

  /// Giá bán hiện tại của từng sản phẩm.
  /// Key = product id, Value = giá bán.
  Map<String, int> prices;

  GameState({
    this.money = 1000,
    this.reputation = 0,
    this.day = 1,
    Map<String, int>? inventory,
    Map<String, int>? prices,
  }) : inventory = inventory ?? {},
        prices = prices ?? {};

  Map<String, dynamic> toJson() {
    return {
      'money': money,
      'reputation': reputation,
      'day': day,
      'inventory': inventory,
      'prices': prices,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    final savedInventory = <String, int>{};
    final savedPrices = <String, int>{};

    final inventoryData = json['inventory'];

    if (inventoryData is Map) {
      inventoryData.forEach((key, value) {
        if (value is num) {
          savedInventory[key.toString()] = value.toInt();
        }
      });
    }

    final pricesData = json['prices'];

    if (pricesData is Map) {
      pricesData.forEach((key, value) {
        if (value is num) {
          savedPrices[key.toString()] = value.toInt();
        }
      });
    }

    return GameState(
      money: json['money'] is num
          ? json['money'].toInt()
          : 1000,
      reputation: json['reputation'] is num
          ? json['reputation'].toInt()
          : 0,
      day: json['day'] is num
          ? json['day'].toInt()
          : 1,
      inventory: savedInventory,
      prices: savedPrices,
    );
  }
}