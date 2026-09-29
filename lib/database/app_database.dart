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
      version: 4,
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
          CREATE TABLE warehouse (
            product_id TEXT PRIMARY KEY,
            quantity INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE shelf (
            product_id TEXT PRIMARY KEY,
            quantity INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE bag (
            product_id TEXT PRIMARY KEY,
            quantity INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE purchase_orders (
            product_id TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            arrival_day INTEGER NOT NULL,
            PRIMARY KEY (product_id, arrival_day)
          )
        ''');

        await db.execute('''
          CREATE TABLE pricing (
            product_id TEXT PRIMARY KEY,
            sell_price INTEGER NOT NULL
          )
        ''');

        await db.insert('player', {
          'id': 1,
          'money': 1000,
          'reputation': 0,
          'day': 1,
        });
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

        if (oldVersion < 3) {
          await db.execute(
            'DROP TABLE IF EXISTS settings',
          );
        }

        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE warehouse (
              product_id TEXT PRIMARY KEY,
              quantity INTEGER NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE shelf (
              product_id TEXT PRIMARY KEY,
              quantity INTEGER NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE bag (
              product_id TEXT PRIMARY KEY,
              quantity INTEGER NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE purchase_orders (
              product_id TEXT NOT NULL,
              quantity INTEGER NOT NULL,
              arrival_day INTEGER NOT NULL,
              PRIMARY KEY (product_id, arrival_day)
            )
          ''');

          // Chuyển hàng tồn kho cũ sang kho mới.
          await db.execute('''
            INSERT OR IGNORE INTO warehouse (
              product_id,
              quantity
            )
            SELECT
              product_id,
              quantity
            FROM inventory
          ''');
        }
      },
    );
  }
}