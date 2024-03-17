import 'package:cafe_orders/db/db_helper.dart';
import 'package:cafe_orders/models/cafe_table.dart';
import 'package:cafe_orders/models/category.dart';
import 'package:cafe_orders/models/good.dart';
import 'package:cafe_orders/models/order.dart';
import 'package:cafe_orders/models/ordered_goods.dart';
import 'package:flutter/material.dart';

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

List<CafeTable> tables = [
  CafeTable(id: 1, name: 'Стол 1'),
  CafeTable(id: 2, name: 'Стол 2'),
  CafeTable(id: 3, name: 'Стол 3'),
  CafeTable(id: 4, name: 'Стол 4'),
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
