class Clinic {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;   // อาจไม่มีใน OSM
  final double? rating;    // OSM มักไม่มี rating

  Clinic({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.rating,
  });
}
