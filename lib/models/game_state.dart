import 'daily_event.dart';

class GameState {
  int money;
  int reputation;
  int day;

  /// Ngày mà Daily Simulation hiện tại đã được tạo.
  ///
  /// Nếu khác với day hiện tại thì cần tạo simulation mới.
  /// Save cũ không có field này sẽ mặc định là 0.
  int simulationDay;

  /// Thời tiết của ngày hiện tại.
  String weather;

  /// Xu hướng nhu cầu của từng sản phẩm trong ngày.
  /// Ví dụ: {'water': 30, 'bread': -10}
  Map<String, int> marketTrends;

  /// Số khách trong ngày hiện tại.
  int customerCount;

  /// Các sự kiện xuất hiện trong ngày hiện tại.
  List<DailyEvent> dailyEvents;

  /// Hàng đang nằm trong kho.
  Map<String, int> warehouse;

  /// Hàng đang nằm trên kệ.
  /// Mỗi sản phẩm có giới hạn riêng, hiện tại mặc định là 10.
  Map<String, int> shelf;

  /// Hàng người chơi đang mang theo.
  /// Tổng số lượng tối đa hiện tại là 10.
  Map<String, int> bag;

  /// Các đơn hàng đang chờ giao.
  /// Mỗi đơn gồm:
  /// productId, quantity, arrivalDay
  List<PurchaseOrder> pendingOrders;

  /// Giá bán hiện tại của từng sản phẩm.
  /// Key = product id, Value = giá bán.
  Map<String, int> prices;

  GameState({
    this.money = 1000,
    this.reputation = 0,
    this.day = 1,
    this.simulationDay = 0,
    this.weather = 'sunny',
    Map<String, int>? marketTrends,
    this.customerCount = 0,
    List<DailyEvent>? dailyEvents,
    Map<String, int>? warehouse,
    Map<String, int>? shelf,
    Map<String, int>? bag,
    List<PurchaseOrder>? pendingOrders,
    Map<String, int>? prices,

    // Tạm giữ để tương thích với các phần cũ của game.
    Map<String, int>? inventory,
  })  : marketTrends = marketTrends ?? {},
        dailyEvents = dailyEvents ?? [],
        warehouse = warehouse ?? inventory ?? {},
        shelf = shelf ?? {},
        bag = bag ?? {},
        pendingOrders = pendingOrders ?? [],
        prices = prices ?? {};

  /// Tổng số hàng hiện đang nằm trong kho.
  int get totalWarehouse {
    return warehouse.values.fold(
      0,
          (sum, quantity) => sum + quantity,
    );
  }

  /// Tổng số hàng người chơi đang mang.
  int get totalBag {
    return bag.values.fold(
      0,
          (sum, quantity) => sum + quantity,
    );
  }

  /// Tổng số hàng đang nằm trên toàn bộ kệ.
  int get totalShelf {
    return shelf.values.fold(
      0,
          (sum, quantity) => sum + quantity,
    );
  }

  /// Tương thích tạm thời với code cũ.
  ///
  /// Sau khi SalesPage được chuyển sang hệ thống mới,
  /// field này sẽ được loại bỏ hoàn toàn.
  Map<String, int> get inventory => warehouse;

  Map<String, dynamic> toJson() {
    return {
      'money': money,
      'reputation': reputation,
      'day': day,
      'simulationDay': simulationDay,
      'weather': weather,
      'marketTrends': marketTrends,
      'customerCount': customerCount,
      'dailyEvents': dailyEvents
          .map((event) => event.toJson())
          .toList(),
      'warehouse': warehouse,
      'shelf': shelf,
      'bag': bag,
      'pendingOrders': pendingOrders
          .map((order) => order.toJson())
          .toList(),
      'prices': prices,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    final savedWarehouse = <String, int>{};
    final savedShelf = <String, int>{};
    final savedBag = <String, int>{};
    final savedPrices = <String, int>{};
    final savedOrders = <PurchaseOrder>[];
    final savedMarketTrends = <String, int>{};
    final savedEvents = <DailyEvent>[];

    final warehouseData = json['warehouse'];

    if (warehouseData is Map) {
      warehouseData.forEach((key, value) {
        if (value is num) {
          savedWarehouse[key.toString()] = value.toInt();
        }
      });
    } else {
      // Dữ liệu save cũ dùng inventory.
      final inventoryData = json['inventory'];

      if (inventoryData is Map) {
        inventoryData.forEach((key, value) {
          if (value is num) {
            savedWarehouse[key.toString()] = value.toInt();
          }
        });
      }
    }

    final shelfData = json['shelf'];

    if (shelfData is Map) {
      shelfData.forEach((key, value) {
        if (value is num) {
          savedShelf[key.toString()] = value.toInt();
        }
      });
    }

    final bagData = json['bag'];

    if (bagData is Map) {
      bagData.forEach((key, value) {
        if (value is num) {
          savedBag[key.toString()] = value.toInt();
        }
      });
    }

    final ordersData = json['pendingOrders'];

    if (ordersData is List) {
      for (final item in ordersData) {
        if (item is Map) {
          savedOrders.add(
            PurchaseOrder.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    final pricesData = json['prices'];

    if (pricesData is Map) {
      pricesData.forEach((key, value) {
        if (value is num) {
          savedPrices[key.toString()] = value.toInt();
        }
      });
    }

    final marketTrendsData = json['marketTrends'];

    if (marketTrendsData is Map) {
      marketTrendsData.forEach((key, value) {
        if (value is num) {
          savedMarketTrends[key.toString()] = value.toInt();
        }
      });
    }

    final eventsData = json['dailyEvents'];

    if (eventsData is List) {
      for (final item in eventsData) {
        if (item is Map) {
          savedEvents.add(
            DailyEvent.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
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
      simulationDay: json['simulationDay'] is num
          ? json['simulationDay'].toInt()
          : 0,
      weather: json['weather']?.toString() ?? 'sunny',
      marketTrends: savedMarketTrends,
      customerCount: json['customerCount'] is num
          ? json['customerCount'].toInt()
          : 0,
      dailyEvents: savedEvents,
      warehouse: savedWarehouse,
      shelf: savedShelf,
      bag: savedBag,
      pendingOrders: savedOrders,
      prices: savedPrices,
    );
  }
}

class PurchaseOrder {
  final String productId;
  final int quantity;
  final int arrivalDay;

  const PurchaseOrder({
    required this.productId,
    required this.quantity,
    required this.arrivalDay,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'arrival_day': arrivalDay,
    };
  }

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      productId: json['product_id']?.toString() ?? '',
      quantity: json['quantity'] is num
          ? json['quantity'].toInt()
          : 0,
      arrivalDay: json['arrival_day'] is num
          ? json['arrival_day'].toInt()
          : 1,
    );
  }
}