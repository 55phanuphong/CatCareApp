import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/clinic.dart';

class OSMClinicService {
  // เผื่อ endpoint หลักล่ม/ช้า จะลองสำรองแทน
  final List<String> _overpassEndpoints = const [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.ru/api/interpreter',
    'https://overpass.nchc.org.tw/api/interpreter',
    'https://overpass.openstreetmap.fr/api/interpreter',
  ];

  /// คำนวณ bounding box แบบคร่าว ๆ จาก lat, lon และรัศมี (กม.)
  Map<String, double> _makeBBox(double lat, double lon, double radiusKm) {
    // 1 องศาละติจูด ≈ 111 กม.
    final dLat = radiusKm / 111.0;

    // 1 องศาลองจิจูด ≈ 111 * cos(lat)
    final dLon = radiusKm / (111.0 * cos(lat * pi / 180.0)).abs();

    return {
      'latMin': lat - dLat,
      'latMax': lat + dLat,
      'lonMin': lon - dLon,
      'lonMax': lon + dLon,
    };
  }

  String _buildQuery({
    required double latMin,
    required double latMax,
    required double lonMin,
    required double lonMax,
  }) {
    return '''
[out:json][timeout:25];
(
  node["amenity"="veterinary"]($latMin,$lonMin,$latMax,$lonMax);
  way["amenity"="veterinary"]($latMin,$lonMin,$latMax,$lonMax);
  relation["amenity"="veterinary"]($latMin,$lonMin,$latMax,$lonMax);
);
out center;
''';
  }

  Future<List<Clinic>> getNearbyVetClinics({
    required double lat,
    required double lon,
    double radiusKm = 5, // ค่าเริ่มต้นค้นในรัศมี 5 กม.
  }) async {
    final bbox = _makeBBox(lat, lon, radiusKm);
    final query = _buildQuery(
      latMin: bbox['latMin']!,
      latMax: bbox['latMax']!,
      lonMin: bbox['lonMin']!,
      lonMax: bbox['lonMax']!,
    );

    // ลองยิงตาม endpoint ที่เตรียมไว้ เมื่อเจอที่ตอบได้ก็หยุด
    for (final endpoint in _overpassEndpoints) {
      try {
        final res = await http
            .post(Uri.parse(endpoint), body: {'data': query})
            .timeout(const Duration(seconds: 25));

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final elements = (data['elements'] as List).cast<Map<String, dynamic>>();

          final clinics = <Clinic>[];
          for (final e in elements) {
            double? latC;
            double? lonC;

            if (e['type'] == 'node') {
              latC = (e['lat'] as num).toDouble();
              lonC = (e['lon'] as num).toDouble();
            } else {
              // way/relation จะมี center
              final center = e['center'];
              if (center != null) {
                latC = (center['lat'] as num).toDouble();
                lonC = (center['lon'] as num).toDouble();
              }
            }

            if (latC == null || lonC == null) continue;

            final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? {};
            clinics.add(
              Clinic(
                id: e['id'].toString(),
                name: (tags['name'] as String?) ?? 'คลินิกรักษาสัตว์',
                latitude: latC,
                longitude: lonC,
                address: tags['addr:full'] ?? tags['addr:street'] ?? tags['addr:place'],
                rating: null, // OSM ไม่ค่อยมี rating
              ),
            );
          }
          return clinics;
        }
      } catch (_) {
        // ถ้า endpoint นี้ล้มเหลว จะลองตัวถัดไป
      }
    }

    // ถ้าลองครบแล้วไม่ได้
    throw Exception('ไม่สามารถโหลดข้อมูลจาก Overpass API ได้ในขณะนี้');
  }
}
