class LaundryItem {
  final int? id;
  final String name;
  final int count;

  LaundryItem({this.id, required this.name, required this.count});

  // Convert a LaundryItem into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'count': count,
    };
  }

  // Convert a Map into a LaundryItem.
  factory LaundryItem.fromMap(Map<String, dynamic> map) {
    return LaundryItem(
      id: map['id'],
      name: map['name'],
      count: map['count'],
    );
  }
}