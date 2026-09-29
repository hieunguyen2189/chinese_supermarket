import 'package:flutter/material.dart';

import '../data/products.dart';
import '../models/game_state.dart';
import '../models/product.dart';
import '../services/save_service.dart';
import '../widgets/chinese_text.dart';

class PurchasePage extends StatefulWidget {
  final GameState gameState;
  final SaveService saveService;

  const PurchasePage({
    super.key,
    required this.gameState,
    required this.saveService,
  });

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  static const int warehouseCapacity = 100;
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

  int _pendingQuantityForArrivalDay(
      Product product,
      int arrivalDay,
      ) {
    return widget.gameState.pendingOrders
        .where(
          (order) =>
      order.productId == product.id &&
          order.arrivalDay == arrivalDay,
    )
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

    final existingPendingQuantity =
    _pendingQuantityForArrivalDay(
      product,
      arrivalDay,
    );

    final pendingForArrivalDay = widget.gameState.pendingOrders
        .where((order) => order.arrivalDay == arrivalDay)
        .fold(
      0,
          (sum, order) => sum + order.quantity,
    );

    final futureWarehouse =
        _totalWarehouse +
            pendingForArrivalDay +
            quantity;

    if (futureWarehouse > warehouseCapacity) {
      _showMessage('仓库空间不够。');
      return;
    }

    setState(() {
      widget.gameState.money -= totalCost;

      widget.gameState.pendingOrders.removeWhere(
            (order) =>
        order.productId == product.id &&
            order.arrivalDay == arrivalDay,
      );

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
    return Scaffold(
      appBar: AppBar(
        title: const ChineseText(
          text: '🛒 进货',
          textStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildSummary(),
            const SizedBox(height: 14),
            _buildExplanation(),
            const SizedBox(height: 14),
            ...products.map(_buildOrderProduct),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _summaryItem(
                '💰',
                '${widget.gameState.money} 元',
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
            fontSize: 18,
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

  Widget _buildExplanation() {
    return Card(
      color: const Color(0xFFFFF3E0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChineseText(
              text: '🚚 进货流程',
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ChineseText(
              text: '现在下单 → 明天送到仓库',
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            ChineseText(
              text: '商品不会马上进入仓库。',
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

  Widget _buildOrderProduct(Product product) {
    final boxes = _boxes(product);
    final quantity = _orderQuantity(product);
    final cost = _orderCost(product);
    final arrivalDay = widget.gameState.day + 1;
    final pending = _pendingQuantityForArrivalDay(
      product,
      arrivalDay,
    );

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
                  style: const TextStyle(fontSize: 34),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChineseText(
                    text: product.hanzi,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ChineseText(
                  text: '${product.buyPrice} 元',
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            if (pending > 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ChineseText(
                  text: '🚚 已订购：$pending',
                  textStyle: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
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
                      text: '$boxes 箱 · $quantity 个',
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
            const SizedBox(height: 4),
            ChineseText(
              text: '$cost 元',
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
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
      ),
    );
  }
}