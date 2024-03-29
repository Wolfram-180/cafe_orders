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
