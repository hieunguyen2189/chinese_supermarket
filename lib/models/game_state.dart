class GameState {
  int money;
  int reputation;
  int day;
  bool showPinyin;

  /// Số lượng từng sản phẩm đang có trong kho.
  /// Key = product id, Value = số lượng.
  Map<String, int> inventory;

  GameState({
    this.money = 1000,
    this.reputation = 0,
    this.day = 1,
    this.showPinyin = true,
    Map<String, int>? inventory,
  }) : inventory = inventory ?? {};

  Map<String, dynamic> toJson() {
    return {
      'money': money,
      'reputation': reputation,
      'day': day,
      'showPinyin': showPinyin,
      'inventory': inventory,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    final savedInventory = <String, int>{};

    final inventoryData = json['inventory'];

    if (inventoryData is Map) {
      inventoryData.forEach((key, value) {
        if (value is num) {
          savedInventory[key.toString()] = value.toInt();
        }
      });
    }

    return GameState(
      money: json['money'] is num ? json['money'].toInt() : 1000,
      reputation: json['reputation'] is num ? json['reputation'].toInt() : 0,
      day: json['day'] is num ? json['day'].toInt() : 1,
      showPinyin: json['showPinyin'] is bool ? json['showPinyin'] : true,
      inventory: savedInventory,
    );
  }
}
