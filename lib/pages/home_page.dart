import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../services/daily_simulation_service.dart';
import '../services/save_service.dart';
import '../widgets/chinese_text.dart';
import 'pricing_page.dart';
import 'purchase_page.dart';
import 'sales_page.dart';
import 'shelf_page.dart';
import 'warehouse_page.dart';
import 'phone_page.dart';

class HomePage extends StatefulWidget {
  final GameState gameState;
  final SaveService saveService;

  const HomePage({
    super.key,
    required this.gameState,
    required this.saveService,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DailySimulationService _dailySimulationService =
  DailySimulationService();

  int _shownSimulationDay = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processMorningDelivery();
    });
  }

  Future<void> _processMorningDelivery() async {
    final state = widget.gameState;

    // Prepare the daily simulation only once for the current day.
    if (state.simulationDay != state.day) {
      await _dailySimulationService.prepareDay(state);

      await widget.saveService.saveGame(state);
    }

    final arrivedOrders = state.pendingOrders
        .where((order) => order.arrivalDay <= state.day)
        .toList();

    final deliveredProducts = <String, int>{};

    if (arrivedOrders.isNotEmpty) {
      for (final order in arrivedOrders) {
        state.warehouse[order.productId] =
            (state.warehouse[order.productId] ?? 0) +
                order.quantity;

        deliveredProducts[order.productId] =
            (deliveredProducts[order.productId] ?? 0) +
                order.quantity;
      }

      state.pendingOrders.removeWhere(
            (order) => order.arrivalDay <= state.day,
      );

      await widget.saveService.saveGame(state);
    }

    if (!mounted) {
      return;
    }

    setState(() {});

    // Show daily simulation only once when entering this day.
    if (_shownSimulationDay != state.day) {
      _shownSimulationDay = state.day;

      await _showDailySimulationDialog();

      if (!mounted) {
        return;
      }
    }

    if (deliveredProducts.isNotEmpty) {
      await _showDeliveryDialog(deliveredProducts);
    }
  }

  Future<void> _showDailySimulationDialog() async {
    final state = widget.gameState;

    final weatherText = _getWeatherText(state.weather);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const ChineseText(
            text: '🌅 今天的情况',
            textStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '🌤️',
                      style: TextStyle(fontSize: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChineseText(
                        text: weatherText,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (state.dailyEvents.isNotEmpty) ...[
                  const ChineseText(
                    text: '今天发生了什么',
                    textStyle: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...state.dailyEvents.map(
                        (event) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ChineseText(
                            text: event.title,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ChineseText(
                            text: event.description,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                const ChineseText(
                  text: '今天的生意会受到这些情况影响。',
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const ChineseText(
                text: '好的',
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
  }

  String _getWeatherText(String weather) {
    switch (weather) {
      case 'sunny':
        return '今天天气很好';
      case 'cloudy':
        return '今天是阴天';
      case 'rainy':
        return '今天下雨了';
      case 'hot':
        return '今天很热';
      default:
        return '今天的天气不错';
    }
  }

  Future<void> _showDeliveryDialog(
      Map<String, int> deliveredProducts,
      ) async {
    final items = <Widget>[];

    for (final entry in deliveredProducts.entries) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              const Text(
                '📦',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChineseText(
                  text:
                  '${_getProductName(entry.key)} × ${entry.value}',
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const ChineseText(
            text: '🚚 货到了！',
            textStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ChineseText(
                text: '今天的订单已经送到仓库。',
                textStyle: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 14),
              ...items,
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const ChineseText(
                text: '好的',
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
  }

  String _getProductName(String productId) {
    switch (productId) {
      case 'apple':
        return '苹果';
      case 'banana':
        return '香蕉';
      case 'water':
        return '水';
      case 'milk':
        return '牛奶';
      case 'bread':
        return '面包';
      default:
        return productId;
    }
  }

  Future<void> _startBusiness() async {
    final hasShelfStock = widget.gameState.shelf.values.any(
          (quantity) => quantity > 0,
    );

    if (!hasShelfStock) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: ChineseText(
              text: '请先把商品放到货架上。',
              textStyle: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalesPage(
          gameState: widget.gameState,
          saveService: widget.saveService,
        ),
      ),
    );

    if (!mounted) return;

    await _processMorningDelivery();

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _openWarehouse() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WarehousePage(
          gameState: widget.gameState,
          saveService: widget.saveService,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _openShelf() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShelfPage(
          gameState: widget.gameState,
          saveService: widget.saveService,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _openPurchase() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchasePage(
          gameState: widget.gameState,
          saveService: widget.saveService,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _openPricing() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PricingPage(
          gameState: widget.gameState,
          saveService: widget.saveService,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.gameState;

    return Scaffold(
      appBar: AppBar(
        title: const ChineseText(
          text: '🏪 我的小超市',
          textStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusCard(state),
            const SizedBox(height: 16),
            _buildStartBusinessCard(),
            const SizedBox(height: 18),
            const ChineseText(
              text: '经营管理',
              textStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildManagementGrid(),
            const SizedBox(height: 18),
            _buildTodayGoalCard(),
            const SizedBox(height: 18),
            Center(
              child: OutlinedButton.icon(
                onPressed: _showSettings,
                icon: const Icon(Icons.settings),
                label: const ChineseText(
                  text: '设置',
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(GameState state) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    icon: '📅',
                    label: '第 ${state.day} 天',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    icon: '⭐',
                    label: '${state.reputation}',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text(
                    '💰',
                    style: TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChineseText(
                      text: '${state.money} 元',
                      textStyle: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9A6700),
                      ),
                    ),
                  ),
                  const ChineseText(
                    text: '现金',
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9A6700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required String icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 8),
        ChineseText(
          text: label,
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStartBusinessCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF66BB6A),
            Color(0xFF43A047),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _startBusiness,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Column(
              children: [
                const Text(
                  '▶',
                  style: TextStyle(
                    fontSize: 34,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const ChineseText(
                  text: '开始营业',
                  textStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                ChineseText(
                  text: '开始今天的生意',
                  textStyle: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Future<void> _openPhone() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhonePage(
          gameState: widget.gameState,
          saveService: widget.saveService,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }
  Widget _buildManagementGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildManagementCard(
          icon: '📱',
          title: '手机',
          subtitle: '查看消息与评价',
          color: const Color(0xFFEDE7F6),
          iconColor: Colors.deepPurple,
          onTap: _openPhone,
        ),
        _buildManagementCard(
          icon: '📦',
          title: '库房',
          subtitle: '仓库 → 背包',
          color: const Color(0xFFE3F2FD),
          iconColor: Colors.blue,
          onTap: _openWarehouse,
        ),
        _buildManagementCard(
          icon: '🛒',
          title: '卖场',
          subtitle: '背包 → 货架',
          color: const Color(0xFFE8F5E9),
          iconColor: Colors.green,
          onTap: _openShelf,
        ),
        _buildManagementCard(
          icon: '🛒',
          title: '进货',
          subtitle: '订购商品',
          color: const Color(0xFFFFF3E0),
          iconColor: Colors.deepOrange,
          onTap: _openPurchase,
        ),
        _buildManagementCard(
          icon: '🏷️',
          title: '定价',
          subtitle: '调整售价',
          color: const Color(0xFFFFEAD5),
          iconColor: Colors.deepOrange,
          onTap: _openPricing,
        ),
        _buildManagementCard(
          icon: '📊',
          title: '经营',
          subtitle: '即将开放',
          color: const Color(0xFFF3E5F5),
          iconColor: Colors.purple,
          onTap: null,
        ),
      ],
    );
  }

  Widget _buildManagementCard({
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      icon,
                      style: const TextStyle(fontSize: 34),
                    ),
                    const SizedBox(height: 8),
                    ChineseText(
                      text: title,
                      textStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ChineseText(
                      text: subtitle,
                      textStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                if (onTap == null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '🔒',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayGoalCard() {
    return Card(
      elevation: 1,
      color: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                '🎯',
                style: TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChineseText(
                    text: '今日目标',
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  ChineseText(
                    text: '进货、补货并开始营业',
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.black45,
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ChineseText(
                  text: '⚙️ 设置',
                  textStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const ChineseText(
                  text: '暂无可调整的设置',
                  textStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}