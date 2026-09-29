import 'package:flutter/material.dart';

import '../data/products.dart';
import '../models/game_state.dart';
import '../models/product.dart';
import '../services/save_service.dart';
import '../widgets/chinese_text.dart';

class WarehousePage extends StatefulWidget {
  final GameState gameState;
  final SaveService saveService;

  const WarehousePage({
    super.key,
    required this.gameState,
    required this.saveService,
  });

  @override
  State<WarehousePage> createState() => _WarehousePageState();
}

class _WarehousePageState extends State<WarehousePage> {
  static const int warehouseCapacity = 100;
  static const int bagCapacity = 10;

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

  Future<void> _putBagBack(Product product) async {
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
    return Scaffold(
      appBar: AppBar(
        title: const ChineseText(
          text: '📦 库房',
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
            ...products.map(_buildProductCard),
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
                '📦',
                '$_totalWarehouse / $warehouseCapacity',
                '仓库',
              ),
            ),
            Expanded(
              child: _summaryItem(
                '🎒',
                '$_totalBag / $bagCapacity',
                '背包',
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

  Widget _buildExplanation() {
    return Card(
      color: const Color(0xFFE3F2FD),
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
              text: '📦 库房操作',
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ChineseText(
              text: '仓库 → 背包',
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            ChineseText(
              text: '每次只能拿一个商品。背包最多携带 10 个商品。',
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
                const SizedBox(width: 8),
                Expanded(
                  child: _stockBox(
                    '🎒',
                    '背包',
                    bag,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: warehouse > 0 &&
                        _totalBag < bagCapacity
                        ? () => _takeFromWarehouse(product)
                        : null,
                    icon: const Icon(
                      Icons.inventory_2_outlined,
                    ),
                    label: const ChineseText(
                      text: '取货',
                      textStyle: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: bag > 0 &&
                        _totalWarehouse < warehouseCapacity
                        ? () => _putBagBack(product)
                        : null,
                    icon: const Icon(
                      Icons.keyboard_return,
                    ),
                    label: const ChineseText(
                      text: '放回仓库',
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
      int value,
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
}