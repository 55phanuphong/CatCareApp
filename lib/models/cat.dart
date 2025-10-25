class Cat {
  final String id;
  final String name;
  final double weight;
  final DateTime birthday;
  final String profileUrl;   // ✅ แก้เป็น String (default "")
  final String gender;
  final String breed;
  final String note;         // ✅ แก้เป็น String (default "")
  final String base64Image;  // ✅ แก้เป็น String (default "")

  Cat({
    required this.id,
    required this.name,
    required this.weight,
    required this.birthday,
    this.profileUrl = "",
    this.gender = "",
    this.breed = "",
    this.note = "",
    this.base64Image = "",
  });

  /// ✅ แปลงจาก Firestore → Object
  factory Cat.fromMap(Map<String, dynamic> map) {
    return Cat(
      id: (map['id'] ?? "").toString(),
      name: (map['name'] ?? "").toString(),
      weight: (map['weight'] ?? 0).toDouble(),
      birthday: DateTime.tryParse(map['birthday'] ?? "") ?? DateTime.now(),
      profileUrl: (map['profileUrl'] ?? "").toString(),
      gender: (map['gender'] ?? "").toString(),
      breed: (map['breed'] ?? "").toString(),
      note: (map['note'] ?? "").toString(),
      base64Image: (map['base64Image'] ?? "").toString(),
    );
  }

  /// ✅ แปลงจาก Object → Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'weight': weight,
      'birthday': birthday.toIso8601String(),
      'profileUrl': profileUrl,
      'gender': gender,
      'breed': breed,
      'note': note,
      'base64Image': base64Image,
    };
  }
}
