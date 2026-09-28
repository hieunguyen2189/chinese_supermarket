import '../database/app_database.dart';
import '../models/game_state.dart';

class SaveService {
  Future<void> saveGame(GameState state) async {
    final db = await AppDatabase.instance.database;

    await db.transaction((txn) async {
      await txn.update(
        'player',
        {
          'money': state.money,
          'reputation': state.reputation,
          'day': state.day,
        },
        where: 'id = ?',
        whereArgs: [1],
      );

      await txn.update(
        'settings',
        {'show_pinyin': state.showPinyin ? 1 : 0},
        where: 'id = ?',
        whereArgs: [1],
      );

      await txn.delete('inventory');

      for (final entry in state.inventory.entries) {
        if (entry.value <= 0) {
          continue;
        }

        await txn.insert('inventory', {
          'product_id': entry.key,
          'quantity': entry.value,
        });
      }

      await txn.delete('pricing');

      for (final entry in state.prices.entries) {
        if (entry.value <= 0) {
          continue;
        }

        await txn.insert('pricing', {
          'product_id': entry.key,
          'sell_price': entry.value,
        });
      }
    });
  }

  Future<GameState> loadGame() async {
    final db = await AppDatabase.instance.database;

    final playerRows = await db.query(
      'player',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    final settingsRows = await db.query(
      'settings',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    final inventoryRows = await db.query('inventory');
    final pricingRows = await db.query('pricing');

    int money = 1000;
    int reputation = 0;
    int day = 1;
    bool showPinyin = true;

    if (playerRows.isNotEmpty) {
      final player = playerRows.first;

      money = player['money'] as int? ?? 1000;
      reputation = player['reputation'] as int? ?? 0;
      day = player['day'] as int? ?? 1;
    }

    if (settingsRows.isNotEmpty) {
      final settings = settingsRows.first;

      showPinyin = (settings['show_pinyin'] as int? ?? 1) == 1;
    }

    final inventory = <String, int>{};

    for (final row in inventoryRows) {
      final productId = row['product_id'] as String?;
      final quantity = row['quantity'] as int?;

      if (productId != null && quantity != null) {
        inventory[productId] = quantity;
      }
    }

    final prices = <String, int>{};

    for (final row in pricingRows) {
      final productId = row['product_id'] as String?;
      final sellPrice = row['sell_price'] as int?;

      if (productId != null && sellPrice != null) {
        prices[productId] = sellPrice;
      }
    }

    return GameState(
      money: money,
      reputation: reputation,
      day: day,
      showPinyin: showPinyin,
      inventory: inventory,
      prices: prices,
    );
  }
}
