import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // проверяем наличие справочников в БД, если нет - загружаем начальные данные
  await DBHelper.checkAndLoadInitialData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Кафе',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const OrderViewScreen(title: 'Список заказов'),
    );
  }
}

//
class Category {
  final int id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

//
class Good {
  final int id;
  final String name;
  final int categoryId;
  final double cost;

  Good({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.cost,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'cost': cost,
    };
  }
}

//
class Table {
  final int id;
  final String name;

  Table({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

//
class Order {
  final int id;
  final String date;
  final String time;
  final int tableId;

  Order({
    required this.id,
    required this.date,
    required this.time,
    required this.tableId,
  });

  Future<void> save() async {
    final db = await DBHelper.getDatabase();
    // -1 для нового заказа
    if (id == -1) {
      final newId = await db.insert(
        'orders',
        toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Создан ноывй заказ с номером $newId');
    } else {
      // обновляем заказ
      await db.update('orders', toMap(), where: 'id = ?', whereArgs: [id]);
      print('Обновлен заказ с номером $id');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'tableId': tableId,
    };
  }
}

//
class OrderedGoods {
  final int orderId;
  final int goodId;
  final int goodCount;

  OrderedGoods({
    required this.orderId,
    required this.goodId,
    required this.goodCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'goodId': goodId,
      'goodCount': goodCount,
    };
  }
}

//
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
  static Future<void> createTable(Table table) async {
    final db = await DBHelper.getDatabase();
    await db.insert(
      'tables',
      table.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Table>> readTables() async {
    final db = await DBHelper.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('tables');

    return List.generate(maps.length, (i) {
      return Table(
        id: maps[i]['id'],
        name: maps[i]['name'],
      );
    });
  }

  static Future<void> updateTable(Table table) async {
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
    for (Table table in tables) {
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

// инициирующие данные для разовой загрузки в базу данных

List<Category> categories = [
  Category(id: 1, name: 'Напитки'),
  Category(id: 2, name: 'Первые блюда'),
  Category(id: 3, name: 'Вторые блюда'),
  Category(id: 4, name: 'Десерты'),
  Category(id: 5, name: 'Алкоголь'),
];

List<Good> goods = [
  Good(id: 1, name: '''Чай черный''', categoryId: 1, cost: 50),
  Good(id: 2, name: 'Кофе эспрессо', categoryId: 1, cost: 70),
  Good(id: 3, name: 'Суп мясной', categoryId: 2, cost: 150),
  Good(id: 4, name: 'Борщ', categoryId: 2, cost: 200),
  Good(id: 5, name: 'Котлета куриная', categoryId: 3, cost: 250),
  Good(id: 6, name: 'Рыба жареная', categoryId: 3, cost: 300),
  Good(id: 7, name: 'Мороженое пломбир', categoryId: 4, cost: 100),
  Good(id: 8, name: 'Пирожное песочное', categoryId: 4, cost: 120),
  Good(id: 9, name: 'Водка Царская 50г', categoryId: 5, cost: 175),
  Good(id: 10, name: 'Вино красное сухое, 200г', categoryId: 5, cost: 190),
];

List<Table> tables = [
  Table(id: 1, name: 'Стол 1'),
  Table(id: 2, name: 'Стол 2'),
  Table(id: 3, name: 'Стол 3'),
  Table(id: 4, name: 'Стол 4'),
];

List<Order> orders = [
  Order(id: 1, date: '2024-03-15', time: '12:00', tableId: 1),
  Order(id: 2, date: '2024-03-15', time: '12:30', tableId: 2),
  Order(id: 3, date: '2024-03-15', time: '12:35', tableId: 3),
  Order(id: 4, date: '2024-03-15', time: '12:15', tableId: 4),
  Order(id: 5, date: '2024-03-15', time: '13:30', tableId: 2),
];

List<OrderedGoods> orderedGoods = [
  OrderedGoods(orderId: 1, goodId: 1, goodCount: 2),
  OrderedGoods(orderId: 1, goodId: 3, goodCount: 1),
  OrderedGoods(orderId: 2, goodId: 2, goodCount: 3),
  OrderedGoods(orderId: 2, goodId: 4, goodCount: 2),
  OrderedGoods(orderId: 3, goodId: 5, goodCount: 1),
  OrderedGoods(orderId: 3, goodId: 6, goodCount: 1),
  OrderedGoods(orderId: 4, goodId: 7, goodCount: 2),
  OrderedGoods(orderId: 4, goodId: 8, goodCount: 2),
  OrderedGoods(orderId: 5, goodId: 4, goodCount: 2),
  OrderedGoods(orderId: 5, goodId: 9, goodCount: 2),
];

//
class OrderViewScreen extends StatefulWidget {
  final String title;

  const OrderViewScreen({super.key, required this.title});

  @override
  _OrderViewScreenState createState() => _OrderViewScreenState();
}

class _OrderViewScreenState extends State<OrderViewScreen> {
  late Future<List<Order>> _futureOrders;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _futureOrders = DBHelper.readOrders();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Order>>(
        future: _futureOrders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка: ${snapshot.error}',
              ),
            );
          } else if (snapshot.hasData) {
            final orders = snapshot.data!;
            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return ListTile(
                  title: Text('Заказ №${order.id}'),
                  subtitle: FutureBuilder<double>(
                    future: DBHelper.getOrderTotalCost(order.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Загрузка...');
                      }
                      return Text(
                        'Дата: ${order.date} Время: ${order.time} Стол: ${order.tableId} Итого: ${snapshot.data.toString()}',
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderEditScreen(
                          orderDetails: order,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          } else {
            return const Center(child: Text('Нет данных для отображения'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderEditScreen(
                orderDetails: Order(
                  id: -1,
                  date: DateTime.now().toString(),
                  time: TimeOfDay.now().toString(),
                  tableId: 0,
                ),
              ),
            ),
          );
        },
        tooltip: 'Создать заказ',
        child: const Icon(Icons.add),
      ),
    );
  }
}

//

class OrderEditScreen extends StatefulWidget {
  final Order? orderDetails;

  const OrderEditScreen({super.key, this.orderDetails});

  @override
  _OrderEditScreenState createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends State<OrderEditScreen> {
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  String? _selectedTable;
  List<String> _tables = [];

  @override
  void initState() {
    super.initState();
    _initOrderDetails();
    _fetchTables();
  }

  void _initOrderDetails() {
    if (widget.orderDetails != null) {
      _dateController = TextEditingController(text: widget.orderDetails!.date);
      _timeController = TextEditingController(text: widget.orderDetails!.time);
    } else {
      _dateController = TextEditingController(text: DateTime.now().toString());
      _timeController = TextEditingController(text: TimeOfDay.now().toString());
    }
  }

  Future<void> _fetchTables() async {
    final tablesList = await DBHelper.readTables();
    setState(() {
      _tables = tablesList.map((t) => t.id.toString()).toList();
      if (widget.orderDetails != null) {
        _selectedTable = _tables.firstWhere(
            (name) => name == widget.orderDetails!.tableId.toString());
      }
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orderDetails == null
            ? 'Создание заказа'
            : 'Редактирование заказа'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              _dateController.text.isEmpty
                  ? ElevatedButton(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2022),
                          lastDate: DateTime(2025),
                        );
                        if (picked != null) {
                          setState(() {
                            _dateController.text = picked.toString();
                          });
                        }
                      },
                      child: const Text('Выберите дату'),
                    )
                  : Text('Дата: ${_dateController.text}'),
              _timeController.text.isEmpty
                  ? ElevatedButton(
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _timeController.text = picked.format(context);
                          });
                        }
                      },
                      child: const Text('Выберите время'),
                    )
                  : Text('Время: ${_timeController.text}'),
              DropdownButtonFormField<String>(
                value: _selectedTable,
                hint: const Text('Выберите стол'),
                onChanged: (newValue) {
                  setState(() {
                    _selectedTable = newValue;
                  });
                },
                items: _tables.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_selectedTable != null) {
                    final tableId = _tables.indexOf(_selectedTable!);
                    final order = Order(
                      id: widget.orderDetails?.id ?? -1,
                      date: _dateController.text,
                      time: _timeController.text,
                      tableId: tableId,
                    );
                    await order.save();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Сохранить заказ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// алерты, сообщения
// showDialog(
//   context: context,
//   builder: (BuildContext context) {
//     return alertLessThanZero;
//   },
// );

Widget okButton = TextButton(
  child: const Text("OK"),
  onPressed: () {},
);

AlertDialog alertLessThanZero = AlertDialog(
  title: const Text('Значение меньше ноля'),
  content: const Text('Значение не может быть меьше ноля'),
  actions: [
    okButton,
  ],
);
