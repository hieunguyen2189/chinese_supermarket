import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../services/save_service.dart';
import '../widgets/chinese_text.dart';
import 'inventory_page.dart';
import 'pricing_page.dart';
import 'sales_page.dart';

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
  Future<void> _startBusiness() async {
    final hasInventory = widget.gameState.inventory.values.any(
          (quantity) => quantity > 0,
    );

    if (!hasInventory) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: ChineseText(
              text: '请先进货。',
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

    setState(() {});
  }
  Future<void> _openInventory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryPage(
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

    debugPrint(
      'HOME AFTER PRICING: '
          'gameState=${identityHashCode(widget.gameState)}, '
          'prices=${widget.gameState.prices}',
    );

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
          icon: '📦',
          title: '库存',
          subtitle: '查看商品',
          color: const Color(0xFFE3F2FD),
          iconColor: Colors.blue,
          onTap: _openInventory,
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
          icon: '🛒',
          title: '进货',
          subtitle: '补充商品',
          color: const Color(0xFFE8F5E9),
          iconColor: Colors.green,
          onTap: _openInventory,
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
                      style: const TextStyle(
                        fontSize: 34,
                      ),
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
                        color: Colors.white.withValues(
                          alpha: 0.7,
                        ),
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
                    text: '进货并开始营业',
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