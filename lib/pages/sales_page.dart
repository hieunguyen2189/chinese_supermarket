import 'dart:math';

import 'package:flutter/material.dart';

import '../data/products.dart';
import '../models/game_state.dart';
import '../models/product.dart';
import '../services/customer_review_service.dart';
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

enum _SalesStep {
  customerRequest,
  preparing,
  checking,
  bill,
  payment,
  change,
  customerReaction,
}

enum _CustomerPersonality {
  normal,
  friendly,
  impatient,
  picky,
  bargain,
  generous,
}

class _SalesPageState extends State<SalesPage> {
  int get customersPerDay {
    return widget.gameState.customerCount > 0
        ? widget.gameState.customerCount
        : 10;
  }

  static const int warehouseCapacity = 100;
  static const int shelfCapacityPerProduct = 10;

  final Random _random = Random();

  final CustomerReviewService _customerReviewService =
  CustomerReviewService();

  int _customerIndex = 0;
  int _todayRevenue = 0;
  int _todayCost = 0;
  int _todayTips = 0;
  int _servedCustomers = 0;
  int _todayReputation = 0;

  bool _finished = false;

  _SalesStep _step = _SalesStep.customerRequest;

  final Map<String, int> _preparedItems = {};

  int _chargeAmount = 0;
  int _customerPayment = 0;
  int _changeInput = 0;

  int _currentTip = 0;

  String _customerMessage = '';
  String _currentFeedback = '';

  bool _busy = false;

  late _CustomerPersonality _currentPersonality;

  final List<String> _todayFeedbacks = [];

  final List<_CustomerOrder> _orders = const [
    _CustomerOrder(
      products: {
        'apple': 3,
      },
      request: '我要三个苹果。',
      customerType: '上班族',
      avatar: '👨‍💼',
    ),
    _CustomerOrder(
      products: {
        'banana': 2,
      },
      request: '香蕉给我来两个。',
      customerType: '年轻顾客',
      avatar: '👩',
    ),
    _CustomerOrder(
      products: {
        'water': 2,
      },
      request: '这个，来两瓶水。',
      customerType: '学生',
      avatar: '👨‍🎓',
    ),
    _CustomerOrder(
      products: {
        'milk': 1,
      },
      request: '给我一盒牛奶。',
      customerType: '妈妈',
      avatar: '👩‍🍼',
    ),
    _CustomerOrder(
      products: {
        'bread': 2,
      },
      request: '面包两个，谢谢。',
      customerType: '年轻顾客',
      avatar: '👨',
    ),
    _CustomerOrder(
      products: {
        'apple': 2,
        'water': 2,
      },
      request: '苹果两个，水两瓶。',
      customerType: '上班族',
      avatar: '👩‍💼',
    ),
    _CustomerOrder(
      products: {
        'banana': 3,
        'milk': 1,
      },
      request: '香蕉三个，再来一盒牛奶。',
      customerType: '顾客',
      avatar: '👨‍🦱',
    ),
    _CustomerOrder(
      products: {
        'water': 3,
        'bread': 1,
      },
      request: '水三瓶，面包一个。',
      customerType: '老人',
      avatar: '👴',
    ),
    _CustomerOrder(
      products: {
        'apple': 2,
        'banana': 2,
      },
      request: '苹果给我两个，香蕉也要两个。',
      customerType: '顾客',
      avatar: '👩‍🦰',
    ),
    _CustomerOrder(
      products: {
        'milk': 2,
        'bread': 1,
      },
      request: '牛奶两盒，面包一个。',
      customerType: '上班族',
      avatar: '👨‍💼',
    ),
  ];

  _CustomerOrder get _currentOrder {
    return _orders[_customerIndex % _orders.length];
  }

  Product? _findProduct(String productId) {
    for (final product in products) {
      if (product.id == productId) {
        return product;
      }
    }

    return null;
  }

  int _shelfStock(String productId) {
    return widget.gameState.shelf[productId] ?? 0;
  }

  int _warehouseStock(String productId) {
    return widget.gameState.warehouse[productId] ?? 0;
  }

  int _sellPrice(String productId) {
    final product = _findProduct(productId);

    if (product == null) {
      return 0;
    }

    return widget.gameState.prices[productId] ??
        product.defaultSellPrice;
  }

  int get _billTotal {
    int total = 0;

    for (final entry in _currentOrder.products.entries) {
      total += _sellPrice(entry.key) * entry.value;
    }

    return total;
  }

  int get _preparedTotalItems {
    return _preparedItems.values.fold(
      0,
          (sum, quantity) => sum + quantity,
    );
  }

  int get _requestedTotalItems {
    return _currentOrder.products.values.fold(
      0,
          (sum, quantity) => sum + quantity,
    );
  }

  bool get _isOrderExact {
    if (_preparedItems.length != _currentOrder.products.length) {
      return false;
    }

    for (final entry in _currentOrder.products.entries) {
      if ((_preparedItems[entry.key] ?? 0) != entry.value) {
        return false;
      }
    }

    for (final entry in _preparedItems.entries) {
      if (!_currentOrder.products.containsKey(entry.key)) {
        return false;
      }
    }

    return true;
  }

  // 当前顾客要求的商品中，只要有一个商品已经完全没货，
  // 就无法完成这个订单。
  bool get _hasOrderItemCompletelyOutOfStock {
    for (final entry in _currentOrder.products.entries) {
      final shelfStock = _shelfStock(entry.key);
      final warehouseStock = _warehouseStock(entry.key);

      if (shelfStock <= 0 && warehouseStock <= 0) {
        return true;
      }
    }

    return false;
  }

  String? get _outOfStockProductName {
    for (final entry in _currentOrder.products.entries) {
      final shelfStock = _shelfStock(entry.key);
      final warehouseStock = _warehouseStock(entry.key);

      if (shelfStock <= 0 && warehouseStock <= 0) {
        final product = _findProduct(entry.key);

        if (product != null) {
          return product.hanzi;
        }
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();

    _currentPersonality = _generatePersonality();
  }

  _CustomerPersonality _generatePersonality() {
    final roll = _random.nextInt(100);

    if (roll < 50) {
      return _CustomerPersonality.normal;
    }

    if (roll < 65) {
      return _CustomerPersonality.friendly;
    }

    if (roll < 75) {
      return _CustomerPersonality.impatient;
    }

    if (roll < 85) {
      return _CustomerPersonality.picky;
    }

    if (roll < 93) {
      return _CustomerPersonality.bargain;
    }

    return _CustomerPersonality.generous;
  }

  void _prepareNextCustomer() {
    _currentPersonality = _generatePersonality();
    _currentTip = 0;
    _currentFeedback = '';
  }

  void _addProduct(String productId) {
    if (_busy || _step != _SalesStep.preparing) {
      return;
    }

    final stock = _shelfStock(productId);

    if (stock <= 0) {
      _showMessage('货架上没有这个商品。');
      return;
    }

    final current = _preparedItems[productId] ?? 0;

    if (current >= stock) {
      _showMessage('货架上没有更多了。');
      return;
    }

    setState(() {
      _preparedItems[productId] = current + 1;
    });
  }

  void _removeProduct(String productId) {
    if (_busy || _step != _SalesStep.preparing) {
      return;
    }

    final current = _preparedItems[productId] ?? 0;

    if (current <= 0) {
      return;
    }

    setState(() {
      if (current == 1) {
        _preparedItems.remove(productId);
      } else {
        _preparedItems[productId] = current - 1;
      }
    });
  }

  void _clearPreparedProduct(String productId) {
    if (_busy || _step != _SalesStep.preparing) {
      return;
    }

    setState(() {
      _preparedItems.remove(productId);
    });
  }

  Future<void> _startPreparing() async {
    if (_step != _SalesStep.customerRequest) {
      return;
    }

    setState(() {
      _step = _SalesStep.preparing;
      _customerMessage = '';
    });
  }

  Future<void> _checkOrder() async {
    if (_busy || _step != _SalesStep.preparing) {
      return;
    }

    setState(() {
      _step = _SalesStep.checking;
    });

    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) {
      return;
    }

    if (_isOrderExact) {
      setState(() {
        _customerMessage = '很好，谢谢。';
        _step = _SalesStep.bill;
      });
      return;
    }

    _showOrderCorrection();
  }

  void _showOrderCorrection() {
    final missing = <String, int>{};
    final extra = <String, int>{};

    for (final entry in _currentOrder.products.entries) {
      final prepared = _preparedItems[entry.key] ?? 0;

      if (prepared < entry.value) {
        missing[entry.key] = entry.value - prepared;
      }
    }

    for (final entry in _preparedItems.entries) {
      final requested = _currentOrder.products[entry.key] ?? 0;

      if (entry.value > requested) {
        extra[entry.key] = entry.value - requested;
      }
    }

    String message;

    if (missing.isNotEmpty && extra.isNotEmpty) {
      final missingText = _formatItemList(missing);
      final extraText = _formatItemList(extra);

      message = '还少$missingText。'
          '另外，这些我不要：$extraText。';
    } else if (missing.isNotEmpty) {
      message = '还少${_formatItemList(missing)}。';
    } else if (extra.isNotEmpty) {
      message = '这些我不要：${_formatItemList(extra)}。';
    } else {
      message = '请检查一下订单。';
    }

    setState(() {
      _customerMessage = message;
      _step = _SalesStep.preparing;
    });
  }

  String _formatItemList(Map<String, int> items) {
    final parts = <String>[];

    for (final entry in items.entries) {
      final product = _findProduct(entry.key);

      if (product == null) {
        continue;
      }

      parts.add('${product.hanzi}${entry.value}个');
    }

    return parts.join('、');
  }

  Future<void> _fetchFromWarehouse(String productId) async {
    if (_busy || _step != _SalesStep.preparing) {
      return;
    }

    final warehouseStock = _warehouseStock(productId);

    if (warehouseStock <= 0) {
      await _emergencyPurchase(productId);
      return;
    }

    final shelfStock = _shelfStock(productId);

    if (shelfStock >= shelfCapacityPerProduct) {
      _showMessage('货架上的商品已经满了。');
      return;
    }

    final availableShelfSpace =
        shelfCapacityPerProduct - shelfStock;

    final quantity = min(
      warehouseStock,
      availableShelfSpace,
    );

    if (quantity <= 0) {
      return;
    }

    final product = _findProduct(productId);

    if (product == null) {
      return;
    }

    setState(() {
      _busy = true;
    });

    await _showLoadingDialog(
      title: '取货中...',
      subtitle: '从仓库取${product.hanzi}',
      seconds: 2,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      widget.gameState.warehouse[productId] =
          warehouseStock - quantity;

      widget.gameState.shelf[productId] =
          shelfStock + quantity;

      _busy = false;
    });

    await widget.saveService.saveGame(widget.gameState);

    if (!mounted) {
      return;
    }

    _showMessage('已从仓库补到货架。');
  }

  Future<void> _emergencyPurchase(String productId) async {
    if (_busy) {
      return;
    }

    final product = _findProduct(productId);

    if (product == null) {
      return;
    }

    final shelfStock = _shelfStock(productId);

    if (shelfStock >= shelfCapacityPerProduct) {
      _showMessage('货架上的商品已经满了。');
      return;
    }

    final needed = _currentOrder.products[productId] ?? 1;

    final prepared = _preparedItems[productId] ?? 0;

    final missing =
    needed > prepared ? needed - prepared : 1;

    final availableSpace =
        shelfCapacityPerProduct - shelfStock;

    final maxAffordable =
    product.buyPrice > 0
        ? widget.gameState.money ~/ product.buyPrice
        : availableSpace;

    final quantity = min(
      min(missing, availableSpace),
      maxAffordable,
    );

    if (quantity <= 0) {
      _showMessage('现金不够。');
      return;
    }

    final confirmed = await _showEmergencyPurchaseDialog(
      product,
      quantity,
    );

    if (!confirmed || !mounted) {
      return;
    }

    final totalCost = product.buyPrice * quantity;

    if (totalCost > widget.gameState.money) {
      _showMessage('现金不够。');
      return;
    }

    setState(() {
      _busy = true;
    });

    await _showLoadingDialog(
      title: '紧急进货中...',
      subtitle: '正在从隔壁店进货',
      seconds: 4,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      widget.gameState.money -= totalCost;

      widget.gameState.shelf[productId] =
          shelfStock + quantity;

      _todayCost += totalCost;

      _busy = false;
    });

    await widget.saveService.saveGame(widget.gameState);

    if (!mounted) {
      return;
    }

    _showMessage('紧急进货到了。');
  }

  Future<bool> _showEmergencyPurchaseDialog(
      Product product,
      int quantity,
      ) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final total = product.buyPrice * quantity;

        return AlertDialog(
          title: const ChineseText(
            text: '紧急进货',
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChineseText(
                text: product.hanzi,
                textStyle: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ChineseText(
                text:
                '$quantity个 × ${product.buyPrice}元 = $total元',
                textStyle: const TextStyle(
                  fontSize: 17,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ChineseText(
                text:
                '现金：${widget.gameState.money}元',
                textStyle: const TextStyle(
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const ChineseText(
                text: '取消',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
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
    ) ??
        false;
  }

  Future<void> _showLoadingDialog({
    required String title,
    required String subtitle,
    required int seconds,
  }) async {
    var closed = false;

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
                const SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 18),
                ChineseText(
                  text: title,
                  textStyle: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ChineseText(
                  text: subtitle,
                  textStyle: const TextStyle(
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

    await Future.delayed(Duration(seconds: seconds));

    if (mounted && !closed) {
      closed = true;
      Navigator.of(context).pop();
    }

    await dialogFuture;
  }

  Future<void> _openBill() async {
    if (_step != _SalesStep.bill) {
      return;
    }

    setState(() {
      _chargeAmount = _billTotal;
    });
  }

  Future<void> _submitCharge() async {
    if (_busy || _step != _SalesStep.bill) {
      return;
    }

    if (_chargeAmount <= 0) {
      _showMessage('请输入收款金额。');
      return;
    }

    if (_chargeAmount > _billTotal) {
      setState(() {
        _customerMessage = '不是这个价格。太贵了。';
      });
      return;
    }

    final revenue = _chargeAmount;

    int cost = 0;

    for (final entry in _currentOrder.products.entries) {
      final product = _findProduct(entry.key);

      if (product != null) {
        cost += product.buyPrice * entry.value;
      }
    }

    setState(() {
      _todayRevenue += revenue;
      _todayCost += cost;

      _step = _SalesStep.payment;

      _customerPayment = _generateCustomerPayment(
        _billTotal,
      );

      _currentTip = _generateTip(_billTotal);

      if (_currentTip > 0) {
        _customerPayment += _currentTip;
      }

      _customerMessage = '好的，给你钱。';
    });
  }

  int _generateCustomerPayment(int billTotal) {
    if (billTotal <= 10) {
      return billTotal;
    }

    final candidates = <int>[
      billTotal,
      ((billTotal / 10).ceil() * 10),
      ((billTotal / 50).ceil() * 50),
      50,
      100,
    ];

    final valid = candidates
        .where((value) => value >= billTotal)
        .toSet()
        .toList();

    return valid[_random.nextInt(valid.length)];
  }

  int _generateTip(int billTotal) {
    int chance;

    switch (_currentPersonality) {
      case _CustomerPersonality.normal:
        chance = 5;
        break;

      case _CustomerPersonality.friendly:
        chance = 12;
        break;

      case _CustomerPersonality.impatient:
        chance = 2;
        break;

      case _CustomerPersonality.picky:
        chance = 1;
        break;

      case _CustomerPersonality.bargain:
        chance = 1;
        break;

      case _CustomerPersonality.generous:
        chance = 30;
        break;
    }

    if (_random.nextInt(100) >= chance) {
      return 0;
    }

    if (billTotal <= 10) {
      return 1;
    }

    final options = <int>[
      1,
      2,
      5,
    ];

    return options[_random.nextInt(options.length)];
  }

  Future<void> _openChangeStep() async {
    if (_step != _SalesStep.payment) {
      return;
    }

    if (_customerPayment == _chargeAmount) {
      await _completePaymentAndContinue();
      return;
    }

    if (_currentTip > 0 &&
        _customerPayment > _chargeAmount) {
      final expectedChange =
          _customerPayment - _chargeAmount;

      final changeWithoutTip =
          expectedChange - _currentTip;

      if (changeWithoutTip <= 0) {
        setState(() {
          _step = _SalesStep.customerReaction;
          _customerMessage = '不用找了。';
        });
        return;
      }
    }

    setState(() {
      _changeInput = 0;
      _step = _SalesStep.change;
      _customerMessage = '请找我钱。';
    });
  }

  Future<void> _submitChange() async {
    if (_busy || _step != _SalesStep.change) {
      return;
    }

    final expectedChange =
        _customerPayment - _chargeAmount;

    final expectedNormalChange =
    max(0, expectedChange - _currentTip);

    if (_changeInput != expectedNormalChange) {
      setState(() {
        _customerMessage = '找错了，请再算一下。';
      });
      return;
    }

    if (_currentTip > 0) {
      setState(() {
        _customerMessage = '不用找了。';
        _step = _SalesStep.customerReaction;
      });
      return;
    }

    await _completePaymentAndContinue();
  }

  Future<void> _completePaymentAndContinue() async {
    if (_currentTip > 0) {
      _todayTips += _currentTip;
      _todayRevenue += _currentTip;
    }

    _currentFeedback = _generateCustomerFeedback();

    if (_currentFeedback.isNotEmpty) {
      _todayFeedbacks.add(_currentFeedback);
    }

    setState(() {
      _step = _SalesStep.customerReaction;
      _customerMessage = _currentFeedback.isNotEmpty
          ? _currentFeedback
          : '谢谢你。';
    });
  }

  String _generateCustomerFeedback() {
    final roll = _random.nextInt(100);

    switch (_currentPersonality) {
      case _CustomerPersonality.normal:
        if (roll < 55) {
          return '谢谢你。';
        }

        if (roll < 70) {
          return '下次我还来。';
        }

        if (roll < 85) {
          return '东西还不错。';
        }

        return '';

      case _CustomerPersonality.friendly:
        if (roll < 40) {
          return '谢谢你，老板。';
        }

        if (roll < 70) {
          return '东西不错，下次我还来。';
        }

        if (roll < 90) {
          return '你的店很干净。';
        }

        return '老板人很好。';

      case _CustomerPersonality.impatient:
        if (roll < 50) {
          return '谢谢。';
        }

        if (roll < 75) {
          return '下次快一点吧。';
        }

        return '今天人有点多。';

      case _CustomerPersonality.picky:
        if (roll < 35) {
          return '谢谢。';
        }

        if (roll < 60) {
          return '东西还可以。';
        }

        if (roll < 80) {
          return '苹果有点贵。';
        }

        return '货架上的东西太少了。';

      case _CustomerPersonality.bargain:
        if (roll < 40) {
          return '谢谢老板。';
        }

        if (roll < 70) {
          return '下次给我便宜一点吧。';
        }

        return '老板，下次见。';

      case _CustomerPersonality.generous:
        if (roll < 45) {
          return '不用找了。';
        }

        if (roll < 75) {
          return '东西不错，我喜欢。';
        }

        if (roll < 90) {
          return '下次我还来。';
        }

        return '谢谢老板。';
    }
  }

  Future<void> _finishCustomerInteraction() async {
    if (_busy || _step != _SalesStep.customerReaction) {
      return;
    }

    await _completeCustomer();
  }

  Future<void> _completeCustomer() async {
    setState(() {
      _busy = true;
    });

    for (final entry in _preparedItems.entries) {
      final shelfStock = _shelfStock(entry.key);

      widget.gameState.shelf[entry.key] =
          shelfStock - entry.value;
    }

    _servedCustomers++;

    // 用于每日顾客评价。
    widget.gameState.servedCustomersToday++;

    _todayReputation++;

    if (_currentFeedback.contains('太贵') ||
        _currentFeedback.contains('太少') ||
        _currentFeedback.contains('快一点')) {
      _todayReputation--;
    }

    _preparedItems.clear();

    await widget.saveService.saveGame(widget.gameState);

    if (!mounted) {
      return;
    }

    setState(() {
      _busy = false;
      _customerIndex++;

      if (_customerIndex >= customersPerDay) {
        _finished = true;
        return;
      }

      _prepareNextCustomer();

      _step = _SalesStep.customerRequest;
      _chargeAmount = 0;
      _customerPayment = 0;
      _changeInput = 0;
      _customerMessage = '';
    });
  }

  void _skipCustomer() {
    if (_busy) {
      return;
    }

    // 记录跳过的顾客，用于每日评价。
    widget.gameState.skippedCustomersToday++;

    setState(() {
      _customerIndex++;

      _preparedItems.clear();
      _chargeAmount = 0;
      _customerPayment = 0;
      _changeInput = 0;
      _currentTip = 0;
      _currentFeedback = '';
      _customerMessage = '';

      if (_customerIndex >= customersPerDay) {
        _finished = true;
      } else {
        _prepareNextCustomer();
        _step = _SalesStep.customerRequest;
      }
    });
  }

  Future<void> _closeEarly() async {
    if (_busy || _finished) {
      return;
    }

    final outOfStockProduct =
        _outOfStockProductName;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const ChineseText(
            text: '🚪 提前关门',
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: ChineseText(
            text: outOfStockProduct != null
                ? '$outOfStockProduct 已经完全没货了。\n'
                '今天剩下的顾客将无法继续服务。\n\n'
                '确定现在关门吗？'
                : '确定现在关门吗？\n'
                '今天剩下的顾客将不再接待。',
            textStyle: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const ChineseText(
                text: '继续营业',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const ChineseText(
                text: '关闭今天',
                textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    // 当前顾客 + 后面的顾客全部算作跳过。
    final remainingCustomers =
        customersPerDay - _customerIndex;

    if (remainingCustomers > 0) {
      widget.gameState.skippedCustomersToday +=
          remainingCustomers;
    }

    setState(() {
      _preparedItems.clear();
      _chargeAmount = 0;
      _customerPayment = 0;
      _changeInput = 0;
      _currentTip = 0;
      _currentFeedback = '';
      _customerMessage = '';
      _finished = true;
    });

    await widget.saveService.saveGame(widget.gameState);
  }

  Future<void> _nextDay() async {
    // 当前天结束时先生成并保存顾客评价。
    final review =
    _customerReviewService.createDailyReview(
      widget.gameState,
    );

    _customerReviewService.applyReview(
      widget.gameState,
      review,
    );

    widget.gameState.day++;
    widget.gameState.reputation += _todayReputation;

    await widget.saveService.saveGame(widget.gameState);

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

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

  void _inputChargeDigit(int digit) {
    if (_step != _SalesStep.bill) {
      return;
    }

    final next = _chargeAmount * 10 + digit;

    if (next > 999999) {
      return;
    }

    setState(() {
      _chargeAmount = next;
    });
  }

  void _deleteChargeDigit() {
    if (_step != _SalesStep.bill) {
      return;
    }

    setState(() {
      _chargeAmount = _chargeAmount ~/ 10;
    });
  }

  void _inputChangeDigit(int digit) {
    if (_step != _SalesStep.change) {
      return;
    }

    final next = _changeInput * 10 + digit;

    if (next > 999999) {
      return;
    }

    setState(() {
      _changeInput = next;
    });
  }

  void _deleteChangeDigit() {
    if (_step != _SalesStep.change) {
      return;
    }

    setState(() {
      _changeInput = _changeInput ~/ 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return _buildDailyResult();
    }

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
              _buildCustomerCard(),
              const SizedBox(height: 18),
              _buildCurrentStage(),
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
                    text:
                    '$_servedCustomers / $customersPerDay',
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

  Widget _buildCustomerCard() {
    final order = _currentOrder;

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
            Text(
              order.avatar,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 6),
            ChineseText(
              text: order.customerType,
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ChineseText(
              text: order.request,
              textStyle: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            if (_customerMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ChineseText(
                  text: _customerMessage,
                  textStyle: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _customerMessage.contains('少') ||
                        _customerMessage.contains('不要') ||
                        _customerMessage.contains('太贵') ||
                        _customerMessage.contains('错') ||
                        _customerMessage.contains('快一点')
                        ? Colors.deepOrange
                        : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStage() {
    switch (_step) {
      case _SalesStep.customerRequest:
        return _buildRequestStage();

      case _SalesStep.preparing:
        return _buildPreparingStage();

      case _SalesStep.checking:
        return _buildCheckingStage();

      case _SalesStep.bill:
        return _buildBillStage();

      case _SalesStep.payment:
        return _buildPaymentStage();

      case _SalesStep.change:
        return _buildChangeStage();

      case _SalesStep.customerReaction:
        return _buildCustomerReactionStage();
    }
  }

  Widget _buildRequestStage() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const ChineseText(
              text: '记住顾客的要求',
              textStyle: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const ChineseText(
              text: '先记住订单，再开始拿货。',
              textStyle: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _startPreparing,
                child: const ChineseText(
                  text: '开始拿货',
                  textStyle: TextStyle(
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

  Widget _buildPreparingStage() {
    final outOfStock = _hasOrderItemCompletelyOutOfStock;
    final outOfStockProduct = _outOfStockProductName;

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
              text: '📦 准备商品',
              textStyle: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const ChineseText(
              text: '自己记住顾客要什么，然后拿货。',
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),

            if (outOfStock) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.red.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      '⚠️',
                      style: TextStyle(fontSize: 34),
                    ),
                    const SizedBox(height: 6),
                    ChineseText(
                      text: outOfStockProduct != null
                          ? '$outOfStockProduct 已经完全没货了。'
                          : '顾客需要的商品已经没有库存。',
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    const ChineseText(
                      text: '可以关闭今天的营业。',
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            _buildPreparedItems(),
            const SizedBox(height: 18),
            const ChineseText(
              text: '货架上的商品',
              textStyle: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildShelfProducts(),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _preparedTotalItems > 0
                    ? _checkOrder
                    : null,
                child: const ChineseText(
                  text: '检查订单',
                  textStyle: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            if (outOfStock) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _closeEarly,
                  icon: const Icon(
                    Icons.storefront_outlined,
                  ),
                  label: const ChineseText(
                    text: '🚪 关闭今天',
                    textStyle: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(
                      color: Colors.red.shade300,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy ? null : _skipCustomer,
                child: const ChineseText(
                  text: '跳过这位顾客',
                  textStyle: TextStyle(
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

  Widget _buildPreparedItems() {
    if (_preparedItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const ChineseText(
          text: '还没有拿商品。',
          textStyle: TextStyle(
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const ChineseText(
            text: '已经拿的商品',
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._preparedItems.entries.map(
                (entry) {
              final product = _findProduct(entry.key);

              if (product == null) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: ChineseText(
                        text:
                        '${product.hanzi} × ${entry.value}',
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _removeProduct(entry.key);
                      },
                      icon: const Icon(
                        Icons.remove_circle_outline,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _addProduct(entry.key);
                      },
                      icon: const Icon(
                        Icons.add_circle_outline,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _clearPreparedProduct(entry.key);
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShelfProducts() {
    final shelfEntries = widget.gameState.shelf.entries
        .where((entry) => entry.value > 0)
        .toList();

    if (shelfEntries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const ChineseText(
          text: '货架没有商品。',
          textStyle: TextStyle(
            color: Colors.deepOrange,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: shelfEntries.map(
            (entry) {
          final product = _findProduct(entry.key);

          if (product == null) {
            return const SizedBox.shrink();
          }

          final shelfStock = entry.value;
          final warehouseStock =
          _warehouseStock(entry.key);

          return Card(
            elevation: 0,
            color: Colors.grey.shade50,
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
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
                    text: '货架 $shelfStock',
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _busy
                        ? null
                        : () {
                      _addProduct(entry.key);
                    },
                    icon: const Icon(
                      Icons.add_shopping_cart_outlined,
                    ),
                  ),
                  IconButton(
                    tooltip: '从仓库取货',
                    onPressed: _busy
                        ? null
                        : () {
                      _fetchFromWarehouse(
                        entry.key,
                      );
                    },
                    icon: Icon(
                      warehouseStock > 0
                          ? Icons.inventory_2_outlined
                          : Icons.local_shipping_outlined,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildCheckingStage() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 18),
            ChineseText(
              text: '顾客正在检查商品...',
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillStage() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const ChineseText(
              text: '🧾 购物小票',
              textStyle: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._currentOrder.products.entries.map(
                  (entry) {
                final product = _findProduct(entry.key);

                if (product == null) {
                  return const SizedBox.shrink();
                }

                final price = _sellPrice(entry.key);

                return Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            ChineseText(
                              text: product.hanzi,
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.pinyin,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ChineseText(
                        text: '$price × ${entry.value}',
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(height: 22),
            ChineseText(
              text: '合计：$_billTotal 元',
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const ChineseText(
              text: '请计算总价。',
              textStyle: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 22),
            const ChineseText(
              text: '请输入要收顾客多少钱。',
              textStyle: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            _buildMoneyDisplay(_chargeAmount),
            const SizedBox(height: 12),
            _buildNumberPad(
              onDigit: _inputChargeDigit,
              onDelete: _deleteChargeDigit,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _chargeAmount > 0
                    ? _submitCharge
                    : null,
                child: const ChineseText(
                  text: '收款',
                  textStyle: TextStyle(
                    fontSize: 17,
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

  Widget _buildPaymentStage() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '💰',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 10),
            const ChineseText(
              text: '顾客付款',
              textStyle: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ChineseText(
              text: '顾客给你 $_customerPayment 元。',
              textStyle: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ChineseText(
              text: '应收：$_chargeAmount 元',
              textStyle: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            if (_currentTip > 0) ...[
              const SizedBox(height: 8),
              ChineseText(
                text:
                '顾客似乎多给了 $_currentTip 元。',
                textStyle: const TextStyle(
                  fontSize: 15,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _openChangeStep,
                child: const ChineseText(
                  text: '计算找零',
                  textStyle: TextStyle(
                    fontSize: 17,
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

  Widget _buildChangeStage() {
    final expectedChange =
        _customerPayment - _chargeAmount;

    final expectedNormalChange =
    max(0, expectedChange - _currentTip);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Text(
              '🧮',
              style: TextStyle(fontSize: 44),
            ),
            const SizedBox(height: 8),
            const ChineseText(
              text: '找零',
              textStyle: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ChineseText(
              text:
              '顾客给了 $_customerPayment 元。',
              textStyle: const TextStyle(
                fontSize: 17,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            ChineseText(
              text: '收了 $_chargeAmount 元。',
              textStyle: const TextStyle(
                fontSize: 17,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            _buildMoneyDisplay(_changeInput),
            const SizedBox(height: 12),
            _buildNumberPad(
              onDigit: _inputChangeDigit,
              onDelete: _deleteChangeDigit,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _submitChange,
                child: const ChineseText(
                  text: '找钱',
                  textStyle: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ChineseText(
              text: _currentTip > 0
                  ? '正常找零：$expectedNormalChange 元'
                  : '顾客应该收到：$expectedChange 元',
              textStyle: const TextStyle(
                fontSize: 13,
                color: Colors.black38,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerReactionStage() {
    final hasTip = _currentTip > 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              hasTip ? '😊' : '🙂',
              style: const TextStyle(fontSize: 54),
            ),
            const SizedBox(height: 10),
            const ChineseText(
              text: '顾客离店前',
              textStyle: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ChineseText(
                text: _currentFeedback.isNotEmpty
                    ? _currentFeedback
                    : '谢谢你。',
                textStyle: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (hasTip) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ChineseText(
                  text:
                  '顾客给了你 $_currentTip 元小费。',
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _finishCustomerInteraction,
                child: const ChineseText(
                  text: '送走顾客',
                  textStyle: TextStyle(
                    fontSize: 17,
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

  Widget _buildMoneyDisplay(int amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black12,
        ),
      ),
      child: ChineseText(
        text: '$amount 元',
        textStyle: const TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildNumberPad({
    required void Function(int digit) onDigit,
    required VoidCallback onDelete,
  }) {
    final digits = <int>[
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      0,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: digits.map(
            (digit) {
          return SizedBox(
            width: 68,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                onDigit(digit);
              },
              child: Text(
                '$digit',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ).toList()
        ..add(
          SizedBox(
            width: 68,
            height: 48,
            child: OutlinedButton(
              onPressed: onDelete,
              child: const Icon(
                Icons.backspace_outlined,
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildDailyResult() {
    final grossProfit =
        _todayRevenue - _todayCost;

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
                      text:
                      '第 ${widget.gameState.day} 天',
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
                      '其中小费',
                      '+$_todayTips 元',
                      valueColor: Colors.orange,
                    ),
                    _buildResultRow(
                      '商品成本',
                      '-$_todayCost 元',
                      valueColor: Colors.orange,
                    ),
                    const Divider(height: 28),
                    _buildResultRow(
                      '毛利润',
                      '${grossProfit >= 0 ? '+' : ''}'
                          '$grossProfit 元',
                      valueColor: grossProfit >= 0
                          ? Colors.green
                          : Colors.red,
                      large: true,
                    ),
                    _buildResultRow(
                      '声望',
                      '${_todayReputation >= 0 ? '+' : ''}'
                          '$_todayReputation',
                      valueColor: _todayReputation >= 0
                          ? Colors.blue
                          : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            if (_todayFeedbacks.isNotEmpty) ...[
              const SizedBox(height: 18),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const ChineseText(
                        text: '💬 顾客反馈',
                        textStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._todayFeedbacks.map(
                            (feedback) {
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(
                              bottom: 8,
                            ),
                            padding:
                            const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: ChineseText(
                              text: '“$feedback”',
                              textStyle: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                fontWeight: large
                    ? FontWeight.bold
                    : FontWeight.normal,
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
  final Map<String, int> products;
  final String request;
  final String customerType;
  final String avatar;

  const _CustomerOrder({
    required this.products,
    required this.request,
    required this.customerType,
    required this.avatar,
  });
}