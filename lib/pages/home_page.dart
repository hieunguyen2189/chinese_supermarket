import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../services/save_service.dart';
import 'inventory_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = widget.gameState;

    return Scaffold(
      appBar: AppBar(title: const Text('🏪 我的小超市'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '📅 第 ${state.day} 天',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '💰 ${state.money} 元',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '⭐ 声望 ${state.reputation}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton.icon(
                  onPressed: _openInventory,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text(
                    '📦 库存',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 80,
                child: FilledButton(
                  onPressed: () {},
                  child: const Text(
                    '▶ 开始营业',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _showSettings,
                icon: const Icon(Icons.settings),
                label: const Text('设置'),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '⚙️ 设置',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: const Text('拼音'),
                      subtitle: const Text('显示 Pinyin'),
                      value: widget.gameState.showPinyin,
                      onChanged: (value) async {
                        setModalState(() {
                          widget.gameState.showPinyin = value;
                        });

                        setState(() {});

                        await widget.saveService.saveGame(widget.gameState);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
