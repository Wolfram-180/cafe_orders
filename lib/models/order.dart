import 'package:cafe_orders/db/db_helper.dart';
import 'package:sqflite/sqflite.dart';

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
