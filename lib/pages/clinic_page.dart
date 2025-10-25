import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/clinic.dart';
import '../services/osm_clinic_service.dart';

class ClinicPage extends StatefulWidget {
  const ClinicPage({super.key});

  @override
  State<ClinicPage> createState() => _ClinicPageState();
}

class _ClinicPageState extends State<ClinicPage> {
  final _service = OSMClinicService();
  final TextEditingController _radiusController = TextEditingController(text: "5");

  bool _loading = false;
  String? _error;
  List<Clinic> _clinics = [];

  /// ✅ ตรวจสอบสิทธิ์ตำแหน่ง
  Future<void> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'กรุณาเปิดบริการระบุตำแหน่ง (GPS) ในเครื่อง';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw 'แอปไม่ได้รับสิทธิ์ตำแหน่ง (ถูกปฏิเสธถาวร) กรุณาไปเปิดใน Settings';
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw 'ผู้ใช้ปฏิเสธการเข้าถึงตำแหน่ง';
      }
    }
  }

  /// ✅ โหลดคลินิกใกล้ฉัน ตามระยะที่พิมพ์
  Future<void> _loadNearby() async {
    setState(() {
      _loading = true;
      _error = null;
      _clinics = [];
    });

    try {
      await _ensureLocationPermission();
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 🔸 แปลงค่าที่ผู้ใช้พิมพ์เป็นตัวเลข
      final radius = double.tryParse(_radiusController.text.trim()) ?? 5.0;

      final list = await _service.getNearbyVetClinics(
        lat: pos.latitude,
        lon: pos.longitude,
        radiusKm: radius,
      );

      setState(() {
        _clinics = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// ✅ เปิดเส้นทางใน Google Maps
  Future<void> _openDirections(Clinic c) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${c.latitude},${c.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเปิด Google Maps ได้')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: const Text('คลินิกใกล้ฉัน'),
        backgroundColor: const Color(0xFFFFF8E7),
        foregroundColor: Colors.brown,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ✅ แถวพิมพ์รัศมี + ปุ่มค้นหา
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _radiusController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "รัศมี (กม.)",
                      hintText: "เช่น 5 หรือ 10",
                      prefixIcon: const Icon(Icons.map, color: Color(0xFFFF9966)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _loadNearby,
                  icon: const Icon(Icons.search),
                  label: const Text("ค้นหา"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9966),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ ส่วนแสดงผล
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNearby,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadNearby,
                              child: const Text('ลองใหม่'),
                            )
                          ],
                        )
                      : _clinics.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 120),
                                Center(child: Text('ไม่พบคลินิกรักษาสัตว์ในระยะนี้')),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _clinics.length,
                              itemBuilder: (context, i) {
                                final c = _clinics[i];
                                return Card(
                                  color: const Color(0xFFFFC29D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (c.address != null) ...[
                                          const SizedBox(height: 6),
                                          Text(c.address!),
                                        ],
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _openDirections(c),
                                            icon: const Icon(Icons.map),
                                            label: const Text('เส้นทาง'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
