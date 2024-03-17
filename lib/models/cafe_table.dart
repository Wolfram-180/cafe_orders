class CafeTable {
  final int id;
  final String name;

  CafeTable({
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
