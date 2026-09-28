import 'package:flutter/material.dart';

import 'models/game_state.dart';
import 'pages/home_page.dart';
import 'services/save_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ChineseSupermarketApp());
}

class ChineseSupermarketApp extends StatelessWidget {
  const ChineseSupermarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chinese Supermarket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const GameLoader(),
    );
  }
}

class GameLoader extends StatefulWidget {
  const GameLoader({super.key});

  @override
  State<GameLoader> createState() => _GameLoaderState();
}

class _GameLoaderState extends State<GameLoader> {
  final SaveService _saveService = SaveService();

  GameState? _gameState;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    final state = await _saveService.loadGame();

    if (!mounted) return;

    setState(() {
      _gameState = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_gameState == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return HomePage(
      gameState: _gameState!,
      saveService: _saveService,
    );
  }
}