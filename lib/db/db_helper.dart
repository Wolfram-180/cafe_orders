import 'package:cafe_orders/main.dart';
import 'package:cafe_orders/models/category.dart';
import 'package:cafe_orders/models/good.dart';
import 'package:cafe_orders/models/order.dart';
import 'package:cafe_orders/models/ordered_goods.dart';
import 'package:cafe_orders/models/cafe_table.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Future<void> deleteDatabase(String path) =>
      databaseFactory.deleteDatabase(path);

  static Future<Database> getDatabase() async {
    final dbPath = await getDatabasesPath();

    final fullDBPath = join(dbPath, 'cafe.db');

    // удаляем БД для тестирования
    // await deleteDatabase(fullDBPath);

    // создаем БД
    const categoriesCreate =
        'CREATE TABLE categories (id INTEGER PRIMARY KEY, name TEXT);';
    const goodsCreate =
        'CREATE TABLE goods (id INTEGER PRIMARY KEY, name TEXT, categoryId INTEGER, cost REAL, FOREIGN KEY (categoryId) REFERENCES categories (id));';
    const tablesCreate =
        'CREATE TABLE tables (id INTEGER PRIMARY KEY, name TEXT);';
    const ordersCreate =
        'CREATE TABLE orders (id INTEGER PRIMARY KEY, orderNumber TEXT, date TEXT, time TEXT, tableId INTEGER, FOREIGN KEY (tableId) REFERENCES tables (id));';
    const orderedGoodsCreate =
        'CREATE TABLE orderedGoods (orderId INTEGER, goodId INTEGER, goodCount INTEGER, FOREIGN KEY (orderId) REFERENCES orders (id), FOREIGN KEY (goodId) REFERENCES goods (id));';

    const categoriesUpdate =
        'CREATE TABLE IF NOT EXISTS categories (id INTEGER PRIMARY KEY, name TEXT);';
    const goodsUpdate =
        'CREATE TABLE IF NOT EXISTS goods (id INTEGER PRIMARY KEY, name TEXT, categoryId INTEGER, cost REAL, FOREIGN KEY (categoryId) REFERENCES categories (id));';
    const tablesUpdate =
        'CREATE TABLE IF NOT EXISTS tables (id INTEGER PRIMARY KEY, name TEXT);';
    const ordersUpdate =
        'CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY, orderNumber TEXT, date TEXT, time TEXT, tableId INTEGER, FOREIGN KEY (tableId) REFERENCES tables (id));';
    const orderedGoodsUpdate =
        'CREATE TABLE IF NOT EXISTS orderedGoods (orderId INTEGER, goodId INTEGER, goodCount INTEGER, FOREIGN KEY (orderId) REFERENCES orders (id), FOREIGN KEY (goodId) REFERENCES goods (id));';

    return openDatabase(
      fullDBPath,
      onCreate: (db, version) async {
        await db.execute(categoriesCreate);
        await db.execute(goodsCreate);
        await db.execute(tablesCreate);
        await db.execute(ordersCreate);
        await db.execute(orderedGoodsCreate);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 1) {
          await db.execute(categoriesUpdate);
          await db.execute(goodsUpdate);
          await db.execute(tablesUpdate);
          await db.execute(ordersUpdate);
          await db.execute(orderedGoodsUpdate);
        }
      },
      version: 1,
    );
  }

  static Future<double> getOrderTotalCost(int orderId) async {
    final db = await getDatabase();
    final orderedGoodsList = await db.query(
      'orderedGoods',
      where: 'orderId = ?',
      whereArgs: [orderId],
    );

    double totalCost = 0;
    for (var orderedGood in orderedGoodsList) {
      final int goodId = orderedGood['goodId'] as int;
      final int goodCount = orderedGood['goodCount'] as int;

      final goodList = await db.query(
        'goods',
        where: 'id = ?',
        whereArgs: [goodId],
      );

      if (goodList.isNotEmpty) {
        final double cost = goodList[0]['cost'] as double;
        totalCost += cost * goodCount;
      }
    }

    return totalCost;
  }

  // далее - CRUDs для каждой таблицы
  // CRUD Category
  static Future<void> createCategory(Category category) async {
    final db = await DBHelper.getDatabase();
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Category>> readCategories() async {
    final db = await DBHelper.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('categories');

    return List.generate(maps.length, (i) {
      return Category(
        id: maps[i]['id'],
        name: maps[i]['name'],
      );
    });
  }

  static Future<void> updateCategory(Category category) async {
    final db = await DBHelper.getDatabase();
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  static Future<void> deleteCategory(int id) async {
    final db = await DBHelper.getDatabase();
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD Good
  static Future<void> createGood(Good good) async {
    final db = await DBHelper.getDatabase();
    await db.insert(
      'goods',
      good.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Good>> readGoods() async {
    final db = await DBHelper.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('goods');

    return List.generate(maps.length, (i) {
      return Good(
        id: maps[i]['id'],
        name: maps[i]['name'],
        categoryId: maps[i]['categoryId'],
        cost: maps[i]['cost'],
      );
    });
  }

  static Future<void> updateGood(Good good) async {
    final db = await DBHelper.getDatabase();
    await db.update(
      'goods',
      good.toMap(),
      where: 'id = ?',
      whereArgs: [good.id],
    );
  }

  static Future<void> deleteGood(int id) async {
    final db = await DBHelper.getDatabase();
    await db.delete(
      'goods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD Tables
  static Future<void> createTable(CafeTable table) async {
    final db = await DBHelper.getDatabase();
    await db.insert(
      'tables',
      table.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<CafeTable>> readTables() async {
    final db = await DBHelper.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('tables');

    return List.generate(maps.length, (i) {
      return CafeTable(
        id: maps[i]['id'],
        name: maps[i]['name'],
      );
    });
  }

  static Future<void> updateTable(CafeTable table) async {
    final db = await DBHelper.getDatabase();
    await db.update(
      'tables',
      table.toMap(),
      where: 'id = ?',
      whereArgs: [table.id],
    );
  }

  static Future<void> deleteTable(int id) async {
    final db = await DBHelper.getDatabase();
    await db.delete(
      'tables',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD Orders
  static Future<void> createOrder(Order order) async {
    final db = await DBHelper.getDatabase();
    await db.insert(
      'orders',
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Order>> readOrders() async {
    final db = await DBHelper.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('orders');

    return List.generate(maps.length, (i) {
      return Order(
        id: maps[i]['id'],
        date: maps[i]['date'],
        time: maps[i]['time'],
        tableId: maps[i]['tableId'],
      );
    });
  }

  // Update an order
  static Future<void> updateOrder(Order order) async {
    final db = await DBHelper.getDatabase();
    await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  // Delete an order
  static Future<void> deleteOrder(int id) async {
    final db = await DBHelper.getDatabase();
    await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD OrderedGoods
  static Future<void> createOrderedGoods(OrderedGoods orderedGoods) async {
    final db = await DBHelper.getDatabase();
    await db.insert(
      'orderedGoods',
      orderedGoods.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<OrderedGoods>> readOrderedGoodsByOrder(int orderId) async {
    final db = await DBHelper.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'orderedGoods',
      where: 'orderId = ?',
      whereArgs: [orderId],
    );

    return List.generate(maps.length, (i) {
      return OrderedGoods(
        orderId: maps[i]['orderId'],
        goodId: maps[i]['goodId'],
        goodCount: maps[i]['goodCount'],
      );
    });
  }

  static Future<void> updateOrderedGoodsDirect(
    int orderId,
    int goodId,
    int newGoodCount,
    BuildContext context,
  ) async {
    final db = await DBHelper.getDatabase();

    if (newGoodCount > 0) {
      await db.update(
        'orderedGoods',
        {'goodCount': newGoodCount},
        where: 'orderId = ? AND goodId = ?',
        whereArgs: [orderId, goodId],
      );
    } else if (newGoodCount == 0) {
      // если новое кол-во равно 0 - удаляем запись
      await db.delete(
        'orderedGoods',
        where: 'orderId = ? AND goodId = ?',
        whereArgs: [orderId, goodId],
      );
    }
  }

  static Future<void> deleteOrderedGood(int orderId, int goodId) async {
    final db = await DBHelper.getDatabase();
    await db.delete(
      'orderedGoods',
      where: 'orderId = ? AND goodId = ?',
      whereArgs: [orderId, goodId],
    );
  }

  // проверка и загрузка начальных данных
  static Future<void> checkAndLoadInitialData() async {
    final db = await DBHelper.getDatabase();

    // проверяем наличие категорий, если нет - значит БД пустая и грузим всё
    final List<Map<String, dynamic>> categoryCheck =
        await db.query('categories');
    if (categoryCheck.isEmpty) {
      await _loadInitialData(db);
    }
  }

  static Future<void> _loadInitialData(Database db) async {
    for (Category category in categories) {
      await db.insert('categories', category.toMap());
    }
    for (Good good in goods) {
      await db.insert('goods', good.toMap());
    }
    for (CafeTable table in tables) {
      await db.insert('tables', table.toMap());
    }
    for (Order order in orders) {
      await db.insert('orders', order.toMap());
    }
    for (OrderedGoods orderedGood in orderedGoods) {
      await db.insert('orderedGoods', orderedGood.toMap());
    }
  }
}
