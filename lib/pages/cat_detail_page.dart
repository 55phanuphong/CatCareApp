import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/cat.dart';
import '../models/vaccine.dart';
import '../services/cat_service.dart';
import '../services/vaccine_service.dart';
import '../services/notification_service.dart';
import 'add_edit_cat_page.dart';

class CatDetailPage extends StatefulWidget {
  final Cat cat;
  const CatDetailPage({super.key, required this.cat});

  @override
  State<CatDetailPage> createState() => _CatDetailPageState();
}

class _CatDetailPageState extends State<CatDetailPage> {
  final _catService = CatService();
  final _vaccineService = VaccineService();

  /// ✅ คำนวณอายุแมว
  String _calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int years = now.year - birthday.year;
    int months = now.month - birthday.month;
    int days = now.day - birthday.day;
    if (days < 0) {
      months--;
      days += DateTime(now.year, now.month, 0).day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }
    return "$years ปี $months เดือน $days วัน";
  }

  /// ✅ เพิ่มวัคซีนใหม่ (Dropdown + ตั้งเวลา)
  Future<void> _addVaccineDialog(BuildContext context) async {
    String? selectedVaccine;
    DateTime? nextDate;
    TimeOfDay? nextTime;
    String status = "upcoming";

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("เพิ่มวัคซีนใหม่ 💉"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "ชื่อวัคซีน",
                prefixIcon: Icon(Icons.vaccines, color: Colors.deepOrange),
                border: OutlineInputBorder(),
              ),
              value: selectedVaccine,
              hint: const Text("เลือกชื่อวัคซีน"),
              items: const [
                DropdownMenuItem(
                    value: "FVRCP",
                    child: Text("FVRCP (วัคซีนรวมไข้หัด/หวัดแมว)")),
                DropdownMenuItem(
                    value: "Rabies", child: Text("Rabies (พิษสุนัขบ้า)")),
                DropdownMenuItem(
                    value: "FeLV", child: Text("FeLV (ลิวคีเมียแมว)")),
                DropdownMenuItem(
                    value: "FIP", child: Text("FIP (เยื่อบุช่องท้องอักเสบ)")),
                DropdownMenuItem(
                    value: "Chlamydia",
                    child: Text("Chlamydia (ตาอักเสบแบคทีเรีย)")),
                DropdownMenuItem(
                    value: "Bordetella",
                    child: Text("Bordetella (โรคทางเดินหายใจ)")),
                DropdownMenuItem(
                    value: "Calicivirus",
                    child: Text("Calicivirus (หวัดแมวชนิดรุนแรง)")),
                DropdownMenuItem(
                    value: "Panleukopenia",
                    child: Text("Panleukopenia (ลำไส้อักเสบไวรัส)")),
              ],
              onChanged: (value) => selectedVaccine = value,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(
                labelText: "สถานะวัคซีน",
                prefixIcon: Icon(Icons.access_time, color: Colors.blueGrey),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "upcoming", child: Text("🕒 รอวันฉีด")),
                DropdownMenuItem(value: "done", child: Text("✅ ฉีดแล้ว")),
              ],
              onChanged: (value) => status = value!,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text(nextDate != null
                  ? "เลือกวัน (${nextDate!.toLocal().toString().split(' ')[0]})"
                  : "เลือกวัน"),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime(2100),
                );
                if (picked != null) nextDate = picked;
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.access_time),
              label: Text(nextTime != null
                  ? "เลือกเวลา (${nextTime!.format(ctx)})"
                  : "เลือกเวลา"),
              onPressed: () async {
                final picked = await showTimePicker(
                  context: ctx,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) nextTime = picked;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("ยกเลิก")),
          ElevatedButton(
            onPressed: () async {
              if (selectedVaccine == null ||
                  nextDate == null ||
                  nextTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("กรุณาเลือกชื่อวัคซีนและวันนัด")),
                );
                return;
              }

              final fullDate = DateTime(
                nextDate!.year,
                nextDate!.month,
                nextDate!.day,
                nextTime!.hour,
                nextTime!.minute,
              );

              final vaccine = Vaccine(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                catId: widget.cat.id,
                catName: widget.cat.name,
                vaccineName: selectedVaccine!,
                status: status,
                nextDate: fullDate,
                vaccineDate: null,
                note: "",
              );

              await _vaccineService.addVaccine(widget.cat.id, vaccine);
              await _scheduleVaccineNotifications(
                  widget.cat.name, selectedVaccine!, fullDate);

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("เพิ่มวัคซีนใหม่สำเร็จ ✅")),
                );
              }
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  /// ✅ ตั้งแจ้งเตือน
  Future<void> _scheduleVaccineNotifications(
      String catName, String vaccineName, DateTime fullDate) async {
    await NotificationService.I.scheduleNotification(
      id: fullDate.millisecondsSinceEpoch.remainder(99999),
      title: "อีก 3 ชั่วโมงจะถึงเวลาฉีดวัคซีนของ $catName",
      body: "วัคซีน: $vaccineName",
      scheduledTime: tz.TZDateTime.from(
          fullDate.subtract(const Duration(hours: 3)), tz.local),
    );
    await NotificationService.I.scheduleNotification(
      id: fullDate.millisecondsSinceEpoch.remainder(88888),
      title: "อีก 1 วันจะถึงเวลาฉีดวัคซีนของ $catName",
      body: "อย่าลืมเตรียมตัวไปคลินิกนะ!",
      scheduledTime: tz.TZDateTime.from(
          fullDate.subtract(const Duration(days: 1)), tz.local),
    );
    await NotificationService.I.scheduleNotification(
      id: fullDate.millisecondsSinceEpoch.remainder(77777),
      title: "ถึงวันฉีดวัคซีนของ $catName แล้ว!",
      body: "วัคซีน: $vaccineName",
      scheduledTime: tz.TZDateTime.from(fullDate, tz.local),
    );
  }

  /// ✅ แก้ไขวัคซีน
  Future<void> _editVaccineDialog(Vaccine vaccine) async {
    DateTime newDate = vaccine.nextDate ?? DateTime.now();
    TimeOfDay newTime =
        TimeOfDay.fromDateTime(vaccine.nextDate ?? DateTime.now());
    String newStatus = vaccine.status;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("แก้ไขวัคซีน ${vaccine.vaccineName}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: newStatus,
              decoration: const InputDecoration(labelText: "สถานะวัคซีน"),
              items: const [
                DropdownMenuItem(value: "upcoming", child: Text("🕒 รอวันฉีด")),
                DropdownMenuItem(value: "done", child: Text("✅ ฉีดแล้ว")),
              ],
              onChanged: (value) => newStatus = value!,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text(
                  "เลือกวัน (${newDate.toLocal().toString().split(' ')[0]})"),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: newDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime(2100),
                );
                if (picked != null) newDate = picked;
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.access_time),
              label: Text("เลือกเวลา (${newTime.format(ctx)})"),
              onPressed: () async {
                final picked =
                    await showTimePicker(context: ctx, initialTime: newTime);
                if (picked != null) newTime = picked;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("ยกเลิก")),
          ElevatedButton(
            child: const Text("บันทึก"),
            onPressed: () async {
              final fullDate = DateTime(newDate.year, newDate.month,
                  newDate.day, newTime.hour, newTime.minute);
              await _vaccineService.updateVaccine(widget.cat.id, vaccine.id,
                  status: newStatus, nextDate: fullDate);

              // ✅ รีเซ็ตแจ้งเตือนใหม่
              if (vaccine.nextDate != null) {
                await NotificationService.I.cancel(
                    vaccine.nextDate!.millisecondsSinceEpoch.remainder(99999));
                await NotificationService.I.cancel(
                    vaccine.nextDate!.millisecondsSinceEpoch.remainder(88888));
                await NotificationService.I.cancel(
                    vaccine.nextDate!.millisecondsSinceEpoch.remainder(77777));
              }
              await _scheduleVaccineNotifications(
                  widget.cat.name, vaccine.vaccineName, fullDate);

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("อัปเดตวัคซีนสำเร็จ ✅")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    ImageProvider? imageProvider;

    if (cat.base64Image.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(cat.base64Image));
      } catch (_) {}
    } else if (cat.profileUrl.isNotEmpty) {
      imageProvider = NetworkImage(cat.profileUrl);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text("ข้อมูลของ ${cat.name}"),
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        foregroundColor: Colors.brown,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueGrey),
            tooltip: "แก้ไขข้อมูลแมว",
            onPressed: () async {
              final updatedCat = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditCatPage(cat: cat)),
              );
              if (updatedCat != null && context.mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("อัปเดตข้อมูลแมวสำเร็จ ✅")),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            tooltip: "ลบแมวตัวนี้",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("ยืนยันการลบแมว 🐾"),
                  content: Text("คุณต้องการลบข้อมูลของ ${cat.name} หรือไม่?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("ยกเลิก")),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                      child: const Text("ลบ"),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _catService.deleteCat(cat.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("ลบข้อมูลของ ${cat.name} แล้ว ✅")),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: imageProvider,
              backgroundColor: Colors.grey[300],
              child: imageProvider == null
                  ? const Icon(Icons.pets, size: 50)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFFFFC29D),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("เพศ: ${cat.gender}"),
                      Text("พันธุ์: ${cat.breed}"),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "วันเกิด: ${cat.birthday.toLocal().toString().split(' ')[0]}"),
                      Text("น้ำหนัก: ${cat.weight} kg"),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("หมายเหตุ: ${cat.note.isNotEmpty ? cat.note : '-'}"),
                      Text("อายุ: ${_calculateAge(cat.birthday)}"),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("💉 ตารางวัคซีน",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.brown),
                onPressed: () => _addVaccineDialog(context),
              ),
            ],
          ),
          StreamBuilder<List<Vaccine>>(
            stream: _vaccineService.getVaccinesByCat(cat.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final vaccines = snapshot.data!;
              if (vaccines.isEmpty) return const Text("ยังไม่มีข้อมูลวัคซีน");

              final now = DateTime.now();

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 24,
                    headingRowColor:
                        MaterialStateProperty.all(const Color(0xFFFFE0B2)),
                    columns: const [
                      DataColumn(label: Text("ชื่อวัคซีน")),
                      DataColumn(label: Text("สถานะ")),
                      DataColumn(label: Text("วันนัด")),
                      DataColumn(label: Text("จัดการ")),
                    ],
                    rows: vaccines.map((v) {
                      String statusText = "";
                      Color? rowColor;

                      if (v.status == "done") {
                        statusText = "✅ ฉีดแล้ว";
                        rowColor = Colors.green[100];
                      } else if (v.nextDate != null) {
                        final diff = v.nextDate!.difference(now).inDays;
                        if (diff <= 3 && diff >= 0) {
                          statusText = "⚠️ ใกล้วันนัด";
                          rowColor = Colors.yellow[100];
                        } else if (diff < 0) {
                          statusText = "❌ เลยวันนัดแล้ว";
                          rowColor = Colors.red[100];
                        } else {
                          statusText = "🕒 รอวันฉีด";
                          rowColor = Colors.orange[100];
                        }
                      }

                      return DataRow(
                        color: MaterialStateProperty.all(rowColor),
                        cells: [
                          DataCell(Text(v.vaccineName)),
                          DataCell(Text(statusText)),
                          DataCell(Text(v.nextDate != null
                              ? "${v.nextDate!.toLocal()}".split(".")[0]
                              : "-")),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editVaccineDialog(v),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _vaccineService.deleteVaccine(cat.id, v.id),
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
