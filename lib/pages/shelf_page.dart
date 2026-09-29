import 'package:flutter/material.dart';

import '../data/products.dart';
import '../models/game_state.dart';
import '../models/product.dart';
import '../services/save_service.dart';
import '../widgets/chinese_text.dart';

class ShelfPage extends StatefulWidget {
  final GameState gameState;
  final SaveService saveService;

  const ShelfPage({
    super.key,
    required this.gameState,
    required this.saveService,
  });

  @override
  State<ShelfPage> createState() => _ShelfPageState();
}

class _ShelfPageState extends State<ShelfPage> {
  static const int bagCapacity = 10;
  static const int shelfCapacityPerProduct = 10;

  int get _totalBag {
    return widget.gameState.totalBag;
  }

  int get _totalShelf {
    return widget.gameState.totalShelf;
  }

  int _bag(Product product) {
    return widget.gameState.bag[product.id] ?? 0;
  }

  int _shelf(Product product) {
    return widget.gameState.shelf[product.id] ?? 0;
  }

  Future<void> _putOnShelf(Product product) async {
    final bagQuantity = _bag(product);
    final shelfQuantity = _shelf(product);

    if (bagQuantity <= 0) {
      _showMessage('背包里没有这个商品。');
      return;
    }

    if (shelfQuantity >= shelfCapacityPerProduct) {
      _showMessage('这个商品的货架满了。');
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
          text: '🛒 卖场',
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
                '🎒',
                '$_totalBag / $bagCapacity',
                '背包',
              ),
            ),
            Expanded(
              child: _summaryItem(
                '🛒',
                '$_totalShelf',
                '货架商品',
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
      color: const Color(0xFFE8F5E9),
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
              text: '🛒 卖场操作',
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ChineseText(
              text: '背包 → 货架',
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            ChineseText(
              text: '只有放到货架上的商品，顾客才能购买。',
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
    final bag = _bag(product);
    final shelf = _shelf(product);

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
                    '🎒',
                    '背包',
                    bag,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: bag > 0 &&
                        shelf < shelfCapacityPerProduct
                        ? () => _putOnShelf(product)
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
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: shelf > 0 &&
                        _totalBag < bagCapacity
                        ? () => _takeFromShelf(product)
                        : null,
                    icon: const Icon(
                      Icons.remove_shopping_cart_outlined,
                    ),
                    label: const ChineseText(
                      text: '取下',
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
}