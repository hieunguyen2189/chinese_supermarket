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

      await _replaceStock(
        txn,
        'warehouse',
        state.warehouse,
      );

      await _replaceStock(
        txn,
        'shelf',
        state.shelf,
      );

      await _replaceStock(
        txn,
        'bag',
        state.bag,
      );

      await txn.delete('purchase_orders');

      for (final order in state.pendingOrders) {
        if (order.quantity <= 0) {
          continue;
        }

        await txn.insert(
          'purchase_orders',
          {
            'product_id': order.productId,
            'quantity': order.quantity,
            'arrival_day': order.arrivalDay,
          },
        );
      }

      await txn.delete('pricing');

      for (final entry in state.prices.entries) {
        if (entry.value <= 0) {
          continue;
        }

        await txn.insert(
          'pricing',
          {
            'product_id': entry.key,
            'sell_price': entry.value,
          },
        );
      }
    });
  }

  Future<void> _replaceStock(
      dynamic txn,
      String table,
      Map<String, int> stock,
      ) async {
    await txn.delete(table);

    for (final entry in stock.entries) {
      if (entry.value <= 0) {
        continue;
      }

      await txn.insert(
        table,
        {
          'product_id': entry.key,
          'quantity': entry.value,
        },
      );
    }
  }

  Future<GameState> loadGame() async {
    final db = await AppDatabase.instance.database;

    final playerRows = await db.query(
      'player',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    final warehouseRows = await db.query('warehouse');
    final shelfRows = await db.query('shelf');
    final bagRows = await db.query('bag');
    final orderRows = await db.query('purchase_orders');
    final pricingRows = await db.query('pricing');

    int money = 1000;
    int reputation = 0;
    int day = 1;

    if (playerRows.isNotEmpty) {
      final player = playerRows.first;

      money = player['money'] as int? ?? 1000;
      reputation = player['reputation'] as int? ?? 0;
      day = player['day'] as int? ?? 1;
    }

    final warehouse = <String, int>{};

    for (final row in warehouseRows) {
      final productId = row['product_id'] as String?;
      final quantity = row['quantity'] as int?;

      if (productId != null && quantity != null) {
        warehouse[productId] = quantity;
      }
    }

    final shelf = <String, int>{};

    for (final row in shelfRows) {
      final productId = row['product_id'] as String?;
      final quantity = row['quantity'] as int?;

      if (productId != null && quantity != null) {
        shelf[productId] = quantity;
      }
    }

    final bag = <String, int>{};

    for (final row in bagRows) {
      final productId = row['product_id'] as String?;
      final quantity = row['quantity'] as int?;

      if (productId != null && quantity != null) {
        bag[productId] = quantity;
      }
    }

    final pendingOrders = <PurchaseOrder>[];

    for (final row in orderRows) {
      final productId = row['product_id'] as String?;
      final quantity = row['quantity'] as int?;
      final arrivalDay = row['arrival_day'] as int?;

      if (productId != null &&
          quantity != null &&
          arrivalDay != null) {
        pendingOrders.add(
          PurchaseOrder(
            productId: productId,
            quantity: quantity,
            arrivalDay: arrivalDay,
          ),
        );
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
      warehouse: warehouse,
      shelf: shelf,
      bag: bag,
      pendingOrders: pendingOrders,
      prices: prices,
    );
  }
}