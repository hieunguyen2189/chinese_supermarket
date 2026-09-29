import 'package:flutter/material.dart';

import '../data/products.dart';
import '../models/game_state.dart';
import '../models/product.dart';
import '../services/save_service.dart';
import '../widgets/chinese_text.dart';

class InventoryPage extends StatefulWidget {
  final GameState gameState;
  final SaveService saveService;

  const InventoryPage({
    super.key,
    required this.gameState,
    required this.saveService,
  });

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  static const int warehouseCapacity = 100;
  static const int bagCapacity = 10;
  static const int shelfCapacityPerProduct = 10;
  static const int itemsPerBox = 10;

  final Map<String, int> _orderBoxes = {};

  @override
  void initState() {
    super.initState();

    for (final product in products) {
      _orderBoxes[product.id] = 1;
    }
  }

  int get _totalWarehouse {
    return widget.gameState.warehouse.values.fold(
      0,
          (sum, quantity) => sum + quantity,
    );
  }

  int get _totalBag {
    return widget.gameState.totalBag;
  }

  int _warehouse(Product product) {
    return widget.gameState.warehouse[product.id] ?? 0;
  }

  int _bag(Product product) {
    return widget.gameState.bag[product.id] ?? 0;
  }

  int _shelf(Product product) {
    return widget.gameState.shelf[product.id] ?? 0;
  }

  int _boxes(Product product) {
    return _orderBoxes[product.id] ?? 1;
  }

  int _orderQuantity(Product product) {
    return _boxes(product) * itemsPerBox;
  }

  int _orderCost(Product product) {
    return _orderQuantity(product) * product.buyPrice;
  }

  int _pendingQuantity(Product product) {
    return widget.gameState.pendingOrders
        .where((order) => order.productId == product.id)
        .fold(
      0,
          (sum, order) => sum + order.quantity,
    );
  }

  void _changeBoxes(Product product, int change) {
    final current = _boxes(product);
    final next = current + change;

    if (next < 1) {
      return;
    }

    setState(() {
      _orderBoxes[product.id] = next;
    });
  }

  Future<void> _placeOrder(Product product) async {
    final quantity = _orderQuantity(product);
    final totalCost = _orderCost(product);
    final arrivalDay = widget.gameState.day + 1;

    if (totalCost > widget.gameState.money) {
      _showMessage('钱不够。');
      return;
    }

    // Tổng số hàng của sản phẩm này đã đặt và sẽ về cùng ngày.
    final existingPendingQuantity = widget.gameState.pendingOrders
        .where(
          (order) =>
      order.productId == product.id &&
          order.arrivalDay == arrivalDay,
    )
        .fold(
      0,
          (sum, order) => sum + order.quantity,
    );

    // Kiểm tra sức chứa kho dự kiến khi đơn hàng về.
    final futureWarehouse =
        _totalWarehouse +
            widget.gameState.pendingOrders
                .where((order) => order.arrivalDay == arrivalDay)
                .fold(
              0,
                  (sum, order) => sum + order.quantity,
            ) +
            quantity;

    if (futureWarehouse > warehouseCapacity) {
      _showMessage('仓库空间不够。');
      return;
    }

    setState(() {
      widget.gameState.money -= totalCost;

      // Xóa các order cùng sản phẩm + cùng ngày đến.
      widget.gameState.pendingOrders.removeWhere(
            (order) =>
        order.productId == product.id &&
            order.arrivalDay == arrivalDay,
      );

      // Gộp đơn mới vào đơn cũ.
      widget.gameState.pendingOrders.add(
        PurchaseOrder(
          productId: product.id,
          quantity: existingPendingQuantity + quantity,
          arrivalDay: arrivalDay,
        ),
      );

      _orderBoxes[product.id] = 1;
    });

    await widget.saveService.saveGame(
      widget.gameState,
    );

    _showMessage('订单已下，明天到货。');
  }

  Future<void> _takeFromWarehouse(Product product) async {
    final warehouseQuantity = _warehouse(product);

    if (warehouseQuantity <= 0) {
      _showMessage('仓库没有这个商品。');
      return;
    }

    if (_totalBag >= bagCapacity) {
      _showMessage('背包满了。');
      return;
    }

    setState(() {
      widget.gameState.warehouse[product.id] =
          warehouseQuantity - 1;

      widget.gameState.bag[product.id] =
          _bag(product) + 1;
    });

    await widget.saveService.saveGame(
      widget.gameState,
    );
  }

  Future<void> _putBagToShelf(Product product) async {
    final bagQuantity = _bag(product);

    if (bagQuantity <= 0) {
      _showMessage('背包里没有这个商品。');
      return;
    }

    final shelfQuantity = _shelf(product);

    if (shelfQuantity >= shelfCapacityPerProduct) {
      _showMessage('货架满了。');
      return;
    }

    setState(() {
      widget.gameState.bag[product.id] =
          bagQuantity - 1;

      widget.gameState.shelf[product.id] =
          shelfQuantity + 1;
    });

    await widget.saveService.saveGame(
      widget.gameState,
    );
  }

  Future<void> _takeFromShelf(Product product) async {
    final shelfQuantity = _shelf(product);

    if (shelfQuantity <= 0) {
      _showMessage('货架没有这个商品。');
      return;
    }

    if (_totalBag >= bagCapacity) {
      _showMessage('背包满了。');
      return;
    }

    setState(() {
      widget.gameState.shelf[product.id] =
          shelfQuantity - 1;

      widget.gameState.bag[product.id] =
          _bag(product) + 1;
    });

    await widget.saveService.saveGame(
      widget.gameState,
    );
  }

  Future<void> _putBagBackToWarehouse(
      Product product,
      ) async {
    final bagQuantity = _bag(product);

    if (bagQuantity <= 0) {
      _showMessage('背包里没有这个商品。');
      return;
    }

    if (_totalWarehouse >= warehouseCapacity) {
      _showMessage('仓库满了。');
      return;
    }

    setState(() {
      widget.gameState.bag[product.id] =
          bagQuantity - 1;

      widget.gameState.warehouse[product.id] =
          _warehouse(product) + 1;
    });

    await widget.saveService.saveGame(
      widget.gameState,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: ChineseText(
            text: message,
            textStyle: const TextStyle(
              color: Colors.white,
            ),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.gameState;

    return Scaffold(
      appBar: AppBar(
        title: const ChineseText(
          text: '📦 库存管理',
          textStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildSummary(state),
            const SizedBox(height: 14),
            _buildStockExplanation(),
            const SizedBox(height: 14),
            ...products.map(_buildProductCard),
            const SizedBox(height: 8),
            _buildOrdersSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(GameState state) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    '💰',
                    '${state.money} 元',
                    '现金',
                  ),
                ),
                Expanded(
                  child: _summaryItem(
                    '📦',
                    '$_totalWarehouse / $warehouseCapacity',
                    '仓库',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    '🎒',
                    '$_totalBag / $bagCapacity',
                    '背包',
                  ),
                ),
                Expanded(
                  child: _summaryItem(
                    '🛒',
                    '${state.totalShelf}',
                    '货架',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
      String icon,
      String value,
      String label,
      ) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(height: 4),
        ChineseText(
          text: value,
          textStyle: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        ChineseText(
          text: label,
          textStyle: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStockExplanation() {
    return Card(
      color: const Color(0xFFE8F5E9),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            ChineseText(
              text: '📋 补货流程',
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ChineseText(
              text: '📦 仓库 → 🎒 背包 → 🛒 货架',
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            ChineseText(
              text: '顾客只能购买货架上的商品。',
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final warehouse = _warehouse(product);
    final bag = _bag(product);
    final shelf = _shelf(product);
    final pending = _pendingQuantity(product);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  product.icon,
                  style: const TextStyle(fontSize: 38),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChineseText(
                    text: product.hanzi,
                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    pinyinStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _stockBox(
                    '📦',
                    '仓库',
                    warehouse,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _stockBox(
                    '🎒',
                    '背包',
                    bag,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _stockBox(
                    '🛒',
                    '货架',
                    '$shelf/$shelfCapacityPerProduct',
                    Colors.green,
                  ),
                ),
              ],
            ),
            if (pending > 0) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ChineseText(
                  text: '🚚 待到货：$pending',
                  textStyle: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: warehouse > 0 &&
                        _totalBag < bagCapacity
                        ? () => _takeFromWarehouse(product)
                        : null,
                    icon: const Icon(
                      Icons.inventory_2_outlined,
                    ),
                    label: const ChineseText(
                      text: '取货',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: bag > 0 &&
                        shelf < shelfCapacityPerProduct
                        ? () => _putBagToShelf(product)
                        : null,
                    icon: const Icon(
                      Icons.add_business,
                    ),
                    label: const ChineseText(
                      text: '上架',
                      textStyle: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: shelf > 0 &&
                        _totalBag < bagCapacity
                        ? () => _takeFromShelf(product)
                        : null,
                    child: const ChineseText(
                      text: '货架 → 背包',
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: bag > 0 &&
                        _totalWarehouse <
                            warehouseCapacity
                        ? () =>
                        _putBagBackToWarehouse(product)
                        : null,
                    child: const ChineseText(
                      text: '背包 → 仓库',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockBox(
      String icon,
      String label,
      Object value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 3),
          ChineseText(
            text: '$label $value',
            textStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const ChineseText(
              text: '🚚 进货',
              textStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const ChineseText(
              text: '下单后明天到货',
              textStyle: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 14),
            ...products.map(_buildOrderProduct),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderProduct(Product product) {
    final boxes = _boxes(product);
    final quantity = _orderQuantity(product);
    final cost = _orderCost(product);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ChineseText(
                  text: product.hanzi,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ChineseText(
                text: '$boxes 箱 · $quantity 个',
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                onPressed: boxes > 1
                    ? () => _changeBoxes(product, -1)
                    : null,
                icon: const Icon(
                  Icons.remove_circle_outline,
                ),
              ),
              Expanded(
                child: Center(
                  child: ChineseText(
                    text: '$cost 元',
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    _changeBoxes(product, 1),
                icon: const Icon(
                  Icons.add_circle_outline,
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _placeOrder(product),
              icon: const Icon(
                Icons.local_shipping_outlined,
              ),
              label: const ChineseText(
                text: '下单 · 明天到货',
                textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}