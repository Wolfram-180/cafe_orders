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
