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

  final Map<String, int> _buyQuantities = {};

  @override
  void initState() {
    super.initState();

    for (final product in products) {
      _buyQuantities[product.id] = 1;
    }
  }

  int get _totalInventory {
    return widget.gameState.inventory.values.fold(
      0,
          (sum, quantity) => sum + quantity,
    );
  }

  int _getBuyQuantity(Product product) {
    return _buyQuantities[product.id] ?? 1;
  }

  void _changeBuyQuantity(Product product, int change) {
    final current = _getBuyQuantity(product);
    final newValue = current + change;

    if (newValue < 1) return;

    setState(() {
      _buyQuantities[product.id] = newValue;
    });
  }

  int _totalCost(Product product) {
    return product.buyPrice * _getBuyQuantity(product);
  }

  Future<void> _buyProduct(Product product) async {
    final quantity = _getBuyQuantity(product);
    final totalCost = _totalCost(product);

    final remainingCapacity =
        warehouseCapacity - _totalInventory;

    if (quantity > remainingCapacity) {
      _showMessage('仓库空间不够。');
      return;
    }

    if (totalCost > widget.gameState.money) {
      _showMessage('钱不够。');
      return;
    }

    setState(() {
      widget.gameState.money -= totalCost;
      widget.gameState.inventory[product.id] =
          (widget.gameState.inventory[product.id] ?? 0) + quantity;

      _buyQuantities[product.id] = 1;
    });

    await widget.saveService.saveGame(widget.gameState);

    _showMessage('进货成功。');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.gameState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 库存'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '💰 ${state.money} 元',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '仓库 $_totalInventory / $warehouseCapacity',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final inventory =
                      state.inventory[product.id] ?? 0;
                  final buyQuantity =
                  _getBuyQuantity(product);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
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
                              const SizedBox(width: 10),
                              Text(
                                '库存 $inventory',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '进货价：${product.buyPrice} 元 / ${product.measureWord}',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              IconButton(
                                onPressed: buyQuantity > 1
                                    ? () => _changeBuyQuantity(
                                  product,
                                  -1,
                                )
                                    : null,
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  '$buyQuantity',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    _changeBuyQuantity(
                                      product,
                                      1,
                                    ),
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '总价 ${_totalCost(product)} 元',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _buyProduct(product),
                              icon: const Icon(
                                Icons.shopping_cart,
                              ),
                              label: const Text('进货'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}