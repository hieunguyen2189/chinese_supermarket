import 'package:flutter/material.dart';

import '../data/products.dart';
import '../models/game_state.dart';
import '../models/product.dart';
import '../services/save_service.dart';
import '../widgets/chinese_text.dart';

class PricingPage extends StatefulWidget {
  final GameState gameState;
  final SaveService saveService;

  const PricingPage({
    super.key,
    required this.gameState,
    required this.saveService,
  });

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  int _getPrice(Product product) {
    return widget.gameState.prices[product.id] ??
        product.defaultSellPrice;
  }

  Future<void> _changePrice(
      Product product,
      int change,
      ) async {
    final before = widget.gameState.prices[product.id];

    final currentPrice =
        widget.gameState.prices[product.id] ??
            product.defaultSellPrice;

    final newPrice = currentPrice + change;

    debugPrint(
      'PRICE BEFORE: ${product.id} = $before',
    );

    debugPrint(
      'PRICE NEW: ${product.id} = $newPrice',
    );

    if (newPrice < product.minSellPrice ||
        newPrice > product.maxSellPrice) {
      return;
    }

    setState(() {
      widget.gameState.prices[product.id] = newPrice;
    });

    debugPrint(
      'PRICE AFTER SETSTATE: '
          '${product.id} = '
          '${widget.gameState.prices[product.id]}',
    );

    await widget.saveService.saveGame(widget.gameState);

    debugPrint(
      'PRICE AFTER SAVE: '
          '${product.id} = '
          '${widget.gameState.prices[product.id]}',
    );
  }

  Future<void> _resetPrice(Product product) async {
    setState(() {
      widget.gameState.prices[product.id] =
          product.defaultSellPrice;
    });

    await widget.saveService.saveGame(widget.gameState);
  }

  String _priceDescription(
      Product product,
      int price,
      ) {
    if (price < product.defaultSellPrice) {
      return '价格较低，顾客更容易购买';
    }

    if (price > product.defaultSellPrice) {
      return '价格较高，顾客可能觉得贵';
    }

    return '建议售价';
  }

  Color _getCardColor(Product product) {
    switch (product.id) {
      case 'apple':
        return const Color(0xFFFFF1F0);
      case 'banana':
        return const Color(0xFFFFF9E6);
      case 'water':
        return const Color(0xFFEAF7FF);
      case 'milk':
        return const Color(0xFFF4F0FF);
      case 'bread':
        return const Color(0xFFFFF3E8);
      default:
        return const Color(0xFFF4F8F2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        title: const Text(
          '🏷️ 定价',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFE8F5E9),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final price = _getPrice(product);

            debugPrint(
              'PRICE BUILD: ${product.id} = $price',
            );

            return Card(
              elevation: 2,
              color: _getCardColor(product),
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.8,
                            ),
                            borderRadius:
                            BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            product.icon,
                            style: const TextStyle(
                              fontSize: 38,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ChineseText(
                            text: product.hanzi,
                            textStyle: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            pinyinStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Text(
                      '进货价：${product.buyPrice} 元 / ${product.measureWord}',
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '建议售价：${product.defaultSellPrice} 元',
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '售价范围：'
                          '${product.minSellPrice}–'
                          '${product.maxSellPrice} 元',
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      _priceDescription(product, price),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                        price > product.defaultSellPrice
                            ? Colors.orange.shade800
                            : Colors.green.shade700,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.75,
                        ),
                        borderRadius:
                        BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed:
                            price > product.minSellPrice
                                ? () => _changePrice(
                              product,
                              -1,
                            )
                                : null,
                            icon: const Icon(
                              Icons.remove_circle,
                              size: 34,
                            ),
                            color: Colors.orange.shade700,
                          ),

                          Expanded(
                            child: Center(
                              child: Text(
                                '$price 元',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          IconButton(
                            onPressed:
                            price < product.maxSellPrice
                                ? () => _changePrice(
                              product,
                              1,
                            )
                                : null,
                            icon: const Icon(
                              Icons.add_circle,
                              size: 34,
                            ),
                            color: Colors.green.shade600,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () =>
                            _resetPrice(product),
                        child: const Text(
                          '恢复建议售价',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}