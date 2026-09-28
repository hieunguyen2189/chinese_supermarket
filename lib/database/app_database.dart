import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();

  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = '$databasePath/chinese_supermarket.db';

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE player (
            id INTEGER PRIMARY KEY,
            money INTEGER NOT NULL,
            reputation INTEGER NOT NULL,
            day INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE inventory (
            product_id TEXT PRIMARY KEY,
            quantity INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE pricing (
            product_id TEXT PRIMARY KEY,
            sell_price INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE settings (
            id INTEGER PRIMARY KEY,
            show_pinyin INTEGER NOT NULL
          )
        ''');

        await db.insert('player', {
          'id': 1,
          'money': 1000,
          'reputation': 0,
          'day': 1,
        });

        await db.insert('settings', {'id': 1, 'show_pinyin': 1});
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE pricing (
              product_id TEXT PRIMARY KEY,
              sell_price INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }
}
