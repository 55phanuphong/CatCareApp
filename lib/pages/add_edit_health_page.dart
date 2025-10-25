import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/health.dart';
import '../models/cat.dart';
import '../services/health_service.dart';
import '../services/cat_service.dart';
import '../services/notification_service.dart';

class AddEditHealthPage extends StatefulWidget {
  final Health? health;
  const AddEditHealthPage({super.key, this.health});

  @override
  State<AddEditHealthPage> createState() => _AddEditHealthPageState();
}

class _AddEditHealthPageState extends State<AddEditHealthPage> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  String? _selectedCatId;
  String? _selectedCatName;

  final HealthService _healthService = HealthService();
  final CatService _catService = CatService();

  @override
  void initState() {
    super.initState();
    if (widget.health != null) {
      _noteController.text = widget.health!.note;
      _date = widget.health!.date;
      _selectedCatId = widget.health!.catId;
      _selectedCatName = widget.health!.catName;

      if (widget.health!.time != null) {
        final parts = widget.health!.time!.split(":");
        if (parts.length == 2) {
          _time = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    print("👆 ปุ่มบันทึกถูกกดแล้ว");

    if (!_formKey.currentState!.validate()) {
      print("❌ ฟอร์มไม่ผ่านการตรวจสอบ");
      return;
    }

    if (_selectedCatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาเลือกแมว")),
      );
      return;
    }

    final health = Health(
      id: widget.health?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      catId: _selectedCatId!,
      catName: _selectedCatName ?? "-",
      title: "สุขภาพ",
      note: _noteController.text.trim(),
      date: _date,
      time:
          "${_time.hour.toString().padLeft(2, "0")}:${_time.minute.toString().padLeft(2, "0")}",
    );

    print("🔥 เริ่มบันทึกข้อมูลสุขภาพลง Firestore...");
    await _healthService.addOrUpdateHealth(health);
    print("✅ บันทึกข้อมูลสุขภาพเรียบร้อย");

    // เวลาเป้าหมาย
    final scheduleDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    print("📅 ตั้งเวลาแจ้งเตือนจริง: $scheduleDateTime");
    print("🕐 เวลาปัจจุบัน: ${DateTime.now()}");

    if (!scheduleDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาเลือกเวลาข้างหน้า")),
      );
      return;
    }

    // สร้างเวลาแจ้งเตือนย่อย
    final before24h = scheduleDateTime.subtract(const Duration(hours: 24));
    final before3h  = scheduleDateTime.subtract(const Duration(hours: 3));
    print("⏰ ก่อน 24 ชม.: $before24h");
    print("⏰ ก่อน 3 ชม.:  $before3h");

    // สร้าง id พื้นฐาน แล้ว offset เพื่อกันชนกัน
    final baseId   = scheduleDateTime.millisecondsSinceEpoch.remainder(90000000);
    final id24h    = baseId + 1;
    final id3h     = baseId + 2;
    final idOnTime = baseId + 3;

    // 1) แจ้งเตือนล่วงหน้า 24 ชั่วโมง (ถ้ายังอยู่อนาคต)
    if (before24h.isAfter(DateTime.now())) {
      await NotificationService.I.scheduleNotification(
        id: id24h,
        title: "📢 อีก 1 วันถึงเวลานัดสุขภาพของ ${health.catName}",
        body: "เตรียมตัวสำหรับ: ${health.note}",
        scheduledTime: before24h,
        payload: health.id,
      );
      print("✅ ตั้งแจ้งเตือนล่วงหน้า 24 ชม. (id=$id24h)");
    } else {
      print("⚠️ ข้ามแจ้งเตือน 24 ชม. เพราะเลยมาแล้ว");
    }

    // 2) แจ้งเตือนล่วงหน้า 3 ชั่วโมง (ถ้ายังอยู่อนาคต)
    if (before3h.isAfter(DateTime.now())) {
      await NotificationService.I.scheduleNotification(
        id: id3h,
        title: "⏳ อีก 3 ชม. จะถึงเวลานัดของ ${health.catName}",
        body: "อย่าลืม: ${health.note}",
        scheduledTime: before3h,
        payload: health.id,
      );
      print("✅ ตั้งแจ้งเตือนล่วงหน้า 3 ชม. (id=$id3h)");
    } else {
      print("⚠️ ข้ามแจ้งเตือน 3 ชม. เพราะเลยมาแล้ว");
    }

    // 3) แจ้งเตือนตอนถึงเวลาจริง
    await NotificationService.I.scheduleNotification(
      id: idOnTime,
      title: "⏰ ถึงเวลานัดสุขภาพของ ${health.catName} แล้ว!",
      body: "รายละเอียด: ${health.note}",
      scheduledTime: scheduleDateTime,
      payload: health.id,
    );
    print("✅ ตั้งแจ้งเตือนตอนถึงเวลา (id=$idOnTime)");

    // แจ้งทันทีเพื่อยืนยัน
    await NotificationService.I.showNow(
      title: "🐾 ตั้งแจ้งเตือนสำเร็จ!",
      body:
          "ตั้งแจ้งเตือนให้ ${health.catName} (ล่วงหน้า 24 ชม., 3 ชม. และตรงเวลา) แล้ว ✅",
    );

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("บันทึกและตั้งแจ้งเตือนสำเร็จ ✅")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text(widget.health == null ? "เพิ่มข้อมูลสุขภาพ" : "แก้ไขข้อมูลสุขภาพ"),
        backgroundColor: const Color(0xFFFFF8E7),
        foregroundColor: Colors.brown,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              StreamBuilder<List<Cat>>(
                stream: _catService.getCats(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final cats = snapshot.data!;
                  return DropdownButtonFormField<String>(
                    value: _selectedCatId,
                    decoration: _inputDecoration("เลือกแมว"),
                    items: cats.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.id,
                        child: Text(cat.name),
                        onTap: () => _selectedCatName = cat.name,
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCatId = value),
                    validator: (value) =>
                        value == null ? "กรุณาเลือกแมว" : null,
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildDatePicker(),
              const SizedBox(height: 15),
              _buildTimePicker(),
              const SizedBox(height: 15),
              TextFormField(
                controller: _noteController,
                decoration: _inputDecoration("รายละเอียด"),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? "กรุณากรอกรายละเอียด" : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9966),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _save,
                  child: const Text("บันทึก",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Card _buildDatePicker() => Card(
        color: const Color(0xFFFFC29D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: const Text("วันที่"),
          subtitle: Text("${_date.toLocal()}".split(" ")[0]),
          trailing: const Icon(Icons.calendar_today, color: Colors.brown),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _date = picked);
          },
        ),
      );

  Card _buildTimePicker() => Card(
        color: const Color(0xFFFFC29D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: const Text("เวลา"),
          subtitle: Text(_time.format(context)),
          trailing: const Icon(Icons.access_time, color: Colors.brown),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _time,
            );
            if (picked != null) setState(() => _time = picked);
          },
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFFFC29D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      );
}
