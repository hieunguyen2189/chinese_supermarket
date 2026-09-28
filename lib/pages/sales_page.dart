import 'package:flutter/material.dart';

import '../data/products.dart';
import '../models/game_state.dart';
import '../models/product.dart';
import '../services/save_service.dart';
import '../widgets/chinese_text.dart';

class SalesPage extends StatefulWidget {
  final GameState gameState;
  final SaveService saveService;

  const SalesPage({
    super.key,
    required this.gameState,
    required this.saveService,
  });

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  static const int customersPerDay = 10;
  static const int warehouseCapacity = 100;

  int _customerIndex = 0;
  int _todayRevenue = 0;
  int _todayCost = 0;
  int _servedCustomers = 0;
  int _todayReputation = 0;

  int _selectedQuantity = 1;

  bool _finished = false;

  final List<_CustomerOrder> _orders = const [
    _CustomerOrder(
      productId: 'apple',
      quantity: 3,
      request: '我要三个苹果。',
    ),
    _CustomerOrder(
      productId: 'banana',
      quantity: 2,
      request: '我要两个香蕉。',
    ),
    _CustomerOrder(
      productId: 'water',
      quantity: 2,
      request: '我要两瓶水。',
    ),
    _CustomerOrder(
      productId: 'milk',
      quantity: 1,
      request: '我要一盒牛奶。',
    ),
    _CustomerOrder(
      productId: 'bread',
      quantity: 2,
      request: '我要两个面包。',
    ),
    _CustomerOrder(
      productId: 'apple',
      quantity: 2,
      request: '我要两个苹果。',
    ),
    _CustomerOrder(
      productId: 'water',
      quantity: 3,
      request: '我要三瓶水。',
    ),
    _CustomerOrder(
      productId: 'banana',
      quantity: 3,
      request: '我要三个香蕉。',
    ),
    _CustomerOrder(
      productId: 'milk',
      quantity: 2,
      request: '我要两盒牛奶。',
    ),
    _CustomerOrder(
      productId: 'bread',
      quantity: 1,
      request: '我要一个面包。',
    ),
  ];

  _CustomerOrder get _currentOrder => _orders[_customerIndex];

  Product? get _currentProduct {
    for (final product in products) {
      if (product.id == _currentOrder.productId) {
        return product;
      }
    }

    return null;
  }

  int get _currentStock {
    return widget.gameState.inventory[_currentOrder.productId] ?? 0;
  }

  int get _currentPrice {
    final product = _currentProduct;

    if (product == null) {
      return 0;
    }

    return widget.gameState.prices[product.id] ??
        product.defaultSellPrice;
  }

  @override
  void initState() {
    super.initState();

    _selectedQuantity = _currentOrder.quantity;

    if (_currentStock < _currentOrder.quantity) {
      _selectedQuantity = _currentStock;
    }
  }

  void _setQuantity(int quantity) {
    if (quantity < 1) {
      return;
    }

    final maxQuantity = _currentOrder.quantity < _currentStock
        ? _currentOrder.quantity
        : _currentStock;

    if (maxQuantity < 1) {
      return;
    }

    setState(() {
      _selectedQuantity =
      quantity > maxQuantity ? maxQuantity : quantity;
    });
  }

  Future<void> _sell() async {
    final product = _currentProduct;

    if (product == null) {
      return;
    }

    final stock = _currentStock;

    if (stock <= 0) {
      _showMessage('库存不够。');
      return;
    }

    final quantity = _selectedQuantity > stock
        ? stock
        : _selectedQuantity;

    final revenue = _currentPrice * quantity;
    final cost = product.buyPrice * quantity;

    setState(() {
      widget.gameState.inventory[product.id] = stock - quantity;

      widget.gameState.money += revenue;

      _todayRevenue += revenue;
      _todayCost += cost;
      _servedCustomers++;
      _todayReputation++;

      _customerIndex++;

      if (_customerIndex >= customersPerDay) {
        _finished = true;
      } else {
        _selectedQuantity = _getNextQuantity();
      }
    });

    await widget.saveService.saveGame(widget.gameState);

    if (_finished) {
      return;
    }
  }

  int _getNextQuantity() {
    final order = _orders[_customerIndex];
    final stock = widget.gameState.inventory[order.productId] ?? 0;

    if (stock <= 0) {
      return 1;
    }

    return order.quantity <= stock ? order.quantity : stock;
  }

  Future<void> _sellAvailable() async {
    final stock = _currentStock;

    if (stock <= 0) {
      _showMessage('库存不够。');
      return;
    }

    setState(() {
      _selectedQuantity = stock < _currentOrder.quantity
          ? stock
          : _currentOrder.quantity;
    });

    await _sell();
  }

  Future<void> _buyMoreStock() async {
    final product = _currentProduct;

    if (product == null) {
      return;
    }

    final currentStock = _currentStock;

    final missingQuantity =
    _currentOrder.quantity > currentStock
        ? _currentOrder.quantity - currentStock
        : 1;

    final remainingCapacity =
        warehouseCapacity - _totalInventory;

    if (remainingCapacity <= 0) {
      _showMessage('仓库空间不够。');
      return;
    }

    final maxAffordableQuantity =
    product.buyPrice > 0
        ? widget.gameState.money ~/ product.buyPrice
        : remainingCapacity;

    final maxQuantity = remainingCapacity < maxAffordableQuantity
        ? remainingCapacity
        : maxAffordableQuantity;

    if (maxQuantity <= 0) {
      _showMessage('钱不够。');
      return;
    }

    final defaultQuantity = missingQuantity > maxQuantity
        ? maxQuantity
        : missingQuantity;

    final quantity = await _showBuyDialog(
      product,
      defaultQuantity,
      maxQuantity,
    );

    if (quantity == null || quantity <= 0) {
      return;
    }

    final totalCost = product.buyPrice * quantity;

    if (totalCost > widget.gameState.money) {
      _showMessage('钱不够。');
      return;
    }

    if (quantity > remainingCapacity) {
      _showMessage('仓库空间不够。');
      return;
    }

    final success = await _showBuyingLoading(product);

    if (!success || !mounted) {
      return;
    }

    setState(() {
      widget.gameState.money -= totalCost;

      widget.gameState.inventory[product.id] =
          (widget.gameState.inventory[product.id] ?? 0) + quantity;

      final newStock =
          widget.gameState.inventory[product.id] ?? 0;

      _selectedQuantity = newStock < _currentOrder.quantity
          ? newStock
          : _currentOrder.quantity;
    });

    await widget.saveService.saveGame(widget.gameState);

    if (!mounted) {
      return;
    }

    _showMessage('进货成功。');
  }

  int get _totalInventory {
    return widget.gameState.inventory.values.fold(
      0,
          (sum, quantity) => sum + quantity,
    );
  }

  Future<int?> _showBuyDialog(
      Product product,
      int defaultQuantity,
      int maxQuantity,
      ) async {
    int quantity = defaultQuantity;

    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final totalCost = product.buyPrice * quantity;

            return AlertDialog(
              title: const ChineseText(
                text: '🛒 进货',
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.icon,
                    style: const TextStyle(fontSize: 46),
                  ),
                  const SizedBox(height: 8),
                  ChineseText(
                    text: product.hanzi,
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ChineseText(
                    text: '进货价：${product.buyPrice} 元 / ${product.measureWord}',
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: quantity > 1
                            ? () {
                          setDialogState(() {
                            quantity--;
                          });
                        }
                            : null,
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ChineseText(
                        text: '$quantity',
                        textStyle: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: quantity < maxQuantity
                            ? () {
                          setDialogState(() {
                            quantity++;
                          });
                        }
                            : null,
                        icon: const Icon(
                          Icons.add_circle_outline,
                          size: 34,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ChineseText(
                    text: '总价：$totalCost 元',
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  ChineseText(
                    text: '现金：${widget.gameState.money} 元',
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const ChineseText(
                    text: '取消',
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, quantity);
                  },
                  child: const ChineseText(
                    text: '进货',
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _showBuyingLoading(Product product) async {
    var loadingDialogClosed = false;

    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.icon,
                  style: const TextStyle(fontSize: 42),
                ),
                const SizedBox(height: 12),
                const ChineseText(
                  text: '进货中...',
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                const SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 16),
                const ChineseText(
                  text: '请稍等。',
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    await Future.delayed(const Duration(seconds: 3));

    if (mounted && !loadingDialogClosed) {
      loadingDialogClosed = true;
      Navigator.of(context).pop();
    }

    await dialogFuture;

    return true;
  }

  void _skipCustomer() {
    setState(() {
      _customerIndex++;
      _todayReputation--;

      if (_customerIndex >= customersPerDay) {
        _finished = true;
      } else {
        _selectedQuantity = _getNextQuantity();
      }
    });
  }

  Future<void> _nextDay() async {
    widget.gameState.day++;
    widget.gameState.reputation += _todayReputation;

    await widget.saveService.saveGame(widget.gameState);

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
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
    if (_finished) {
      return _buildDailyResult();
    }

    final product = _currentProduct;

    if (product == null) {
      return const Scaffold(
        body: Center(
          child: ChineseText(
            text: '商品不存在。',
          ),
        ),
      );
    }

    final stock = _currentStock;
    final requestedQuantity = _currentOrder.quantity;
    final canSell = stock > 0 && _selectedQuantity > 0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const ChineseText(
            text: '🏪 营业中',
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSalesStatus(),
              const SizedBox(height: 18),
              _buildCustomerCard(product),
              const SizedBox(height: 18),
              _buildOrderCard(
                product,
                stock,
                requestedQuantity,
                canSell,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesStatus() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const ChineseText(
                    text: '今日收入',
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  ChineseText(
                    text: '$_todayRevenue 元',
                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 45,
              color: Colors.black12,
            ),
            Expanded(
              child: Column(
                children: [
                  const ChineseText(
                    text: '顾客',
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  ChineseText(
                    text: '$_servedCustomers / $customersPerDay',
                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Product product) {
    return Card(
      elevation: 2,
      color: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '👤',
              style: TextStyle(fontSize: 46),
            ),
            const SizedBox(height: 8),
            const ChineseText(
              text: '顾客',
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ChineseText(
              text: _currentOrder.request,
              textStyle: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            const ChineseText(
              text: '请按订单卖给顾客。',
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
      Product product,
      int stock,
      int requestedQuantity,
      bool canSell,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ChineseText(
              text: '🛒 顾客订单',
              textStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  product.icon,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChineseText(
                    text:
                    '${product.hanzi} × $requestedQuantity',
                    textStyle: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ChineseText(
              text: '库存：$stock',
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: stock >= requestedQuantity
                    ? Colors.green.shade700
                    : Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 6),
            ChineseText(
              text:
              '售价：$_currentPrice 元 / ${product.measureWord}',
              textStyle: const TextStyle(
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 18),
            if (stock >= requestedQuantity)
              _buildQuantitySelector(requestedQuantity),
            if (stock < requestedQuantity)
              _buildStockShortage(stock, requestedQuantity),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canSell ? _sell : null,
                icon: const Icon(Icons.shopping_cart_checkout),
                label: ChineseText(
                  text: '卖出 $_selectedQuantity 个',
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _skipCustomer,
                child: const ChineseText(
                  text: '不卖',
                  textStyle: TextStyle(
                    fontSize: 16,
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

  Widget _buildQuantitySelector(int requestedQuantity) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _selectedQuantity > 1
              ? () => _setQuantity(_selectedQuantity - 1)
              : null,
          icon: const Icon(
            Icons.remove_circle_outline,
            size: 34,
          ),
        ),
        const SizedBox(width: 12),
        ChineseText(
          text: '$_selectedQuantity',
          textStyle: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _selectedQuantity < requestedQuantity
              ? () => _setQuantity(_selectedQuantity + 1)
              : null,
          icon: const Icon(
            Icons.add_circle_outline,
            size: 34,
          ),
        ),
      ],
    );
  }

  Widget _buildStockShortage(
      int stock,
      int requestedQuantity,
      ) {
    return Card(
      color: const Color(0xFFFFF3E0),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const ChineseText(
              text: '库存不够。',
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            ChineseText(
              text:
              '顾客要 $requestedQuantity 个，库存只有 $stock 个。',
              textStyle: const TextStyle(
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _sellAvailable,
                child: ChineseText(
                  text: '卖 $stock 个',
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _buyMoreStock,
                icon: const Icon(Icons.local_shipping_outlined),
                label: const ChineseText(
                  text: '去进货',
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyResult() {
    final grossProfit = _todayRevenue - _todayCost;

    return Scaffold(
      appBar: AppBar(
        title: const ChineseText(
          text: '🌙 今日结算',
          textStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    const Text(
                      '🌙',
                      style: TextStyle(fontSize: 54),
                    ),
                    const SizedBox(height: 8),
                    ChineseText(
                      text: '第 ${widget.gameState.day} 天',
                      textStyle: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildResultRow(
                      '服务顾客',
                      '$_servedCustomers',
                    ),
                    _buildResultRow(
                      '销售收入',
                      '+$_todayRevenue 元',
                      valueColor: Colors.green,
                    ),
                    _buildResultRow(
                      '商品成本',
                      '-$_todayCost 元',
                      valueColor: Colors.orange,
                    ),
                    const Divider(height: 28),
                    _buildResultRow(
                      '毛利润',
                      '${grossProfit >= 0 ? '+' : ''}$grossProfit 元',
                      valueColor: grossProfit >= 0
                          ? Colors.green
                          : Colors.red,
                      large: true,
                    ),
                    _buildResultRow(
                      '声望',
                      '${_todayReputation >= 0 ? '+' : ''}$_todayReputation',
                      valueColor: _todayReputation >= 0
                          ? Colors.blue
                          : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _nextDay,
                icon: const Icon(Icons.arrow_forward),
                label: const ChineseText(
                  text: '进入下一天',
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(
      String label,
      String value, {
        Color? valueColor,
        bool large = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: ChineseText(
              text: label,
              textStyle: TextStyle(
                fontSize: large ? 19 : 16,
                fontWeight:
                large ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          ChineseText(
            text: value,
            textStyle: TextStyle(
              fontSize: large ? 21 : 17,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerOrder {
  final String productId;
  final int quantity;
  final String request;

  const _CustomerOrder({
    required this.productId,
    required this.quantity,
    required this.request,
  });
}