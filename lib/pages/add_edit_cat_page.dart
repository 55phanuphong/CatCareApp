import 'dart:io';
import 'dart:convert'; // ✅ ใช้สำหรับแปลงรูปเป็น Base64
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cat.dart';
import '../services/cat_service.dart';

class AddEditCatPage extends StatefulWidget {
  final Cat? cat;
  const AddEditCatPage({this.cat, super.key});

  @override
  State<AddEditCatPage> createState() => _AddEditCatPageState();
}

class _AddEditCatPageState extends State<AddEditCatPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  String? _gender;
  String? _breed;
  DateTime? _birthday;

  File? _imageFile;
  String _base64Image = ""; // ✅ เก็บ Base64 เป็น String ว่างแทน null

  final _picker = ImagePicker();
  final CatService _catService = CatService();

  final List<String> genders = ["เพศผู้", "เพศเมีย"];
  final List<String> breeds = ["เปอร์เซีย", "สก๊อตติชโฟลด์", "ไทย", "เมนคูน",
                               "อเมริกันช็อตแฮร์", "บริติช ช็อตแฮร์", "เอ็กโซติก", 
                               "เบงกอล", "มันช์กิ้น", "แร็กดอลล์", "สฟิงซ์",
                               "เซอร์วัล", "ไซบีเรียน", "วิเชียรมาศ", "โคราช",
                               "ขาวมณี", "คาราคัล"];

  @override
  void initState() {
    super.initState();
    if (widget.cat != null) {
      _nameController.text = widget.cat!.name;
      _weightController.text = widget.cat!.weight.toString();
      _birthday = widget.cat!.birthday;
      _gender = widget.cat!.gender;
      _breed = widget.cat!.breed;
      _noteController.text = widget.cat!.note;
      _base64Image = widget.cat!.base64Image; // ✅ โหลดรูปเก่า
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // ลดขนาดไฟล์
    );
    if (pickedFile != null) {
      try {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        setState(() {
          _imageFile = file;
          _base64Image = base64Encode(bytes); // ✅ แปลงเป็น Base64
        });
      } catch (e) {
        debugPrint("⚠️ Error reading image: $e");
      }
    }
  }

  Future<void> _saveCat() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาเลือกวันเกิด")),
      );
      return;
    }

    final id = widget.cat == null ? "" : widget.cat!.id;

    final cat = Cat(
      id: id,
      name: _nameController.text.trim(),
      birthday: _birthday!,
      weight: double.tryParse(_weightController.text) ?? 0.0,
      gender: _gender ?? "",
      breed: _breed ?? "",
      note: _noteController.text.trim(),
      base64Image: _base64Image, // ✅ เก็บ Base64 เสมอ
    );

    try {
      await _catService.addOrUpdateCat(cat);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
      );
    }
  }

  Widget _buildInputBox({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC29D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ เลือกรูป: Base64 > File > URL > Default
    ImageProvider? imageProvider;
    if (_base64Image.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(_base64Image));
      } catch (e) {
        debugPrint("⚠️ Base64 decode error: $e");
      }
    } else if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (widget.cat?.profileUrl.isNotEmpty == true) {
      imageProvider = NetworkImage(widget.cat!.profileUrl);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text(widget.cat == null ? "เพิ่มน้องแมว" : "แก้ไขข้อมูลแมว"),
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        foregroundColor: Colors.brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: imageProvider,
                  backgroundColor: Colors.grey[300],
                  child: imageProvider == null
                      ? const Icon(Icons.add_a_photo, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // 🐱 ฟิลด์ต่าง ๆ
              _buildInputBox(
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "ชื่อแมว",
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "กรุณาใส่ชื่อแมว" : null,
                ),
              ),

              _buildInputBox(
                child: DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(border: InputBorder.none),
                  hint: const Text("เพศ"),
                  items: genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (value) => setState(() => _gender = value),
                ),
              ),

              _buildInputBox(
                child: DropdownButtonFormField<String>(
                  value: _breed,
                  decoration: const InputDecoration(border: InputBorder.none),
                  hint: const Text("พันธุ์"),
                  items: breeds
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (value) => setState(() => _breed = value),
                ),
              ),

              _buildInputBox(
                child: TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "น้ำหนัก (กิโลกรัม)",
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value == null || value.isEmpty ? "กรุณาใส่น้ำหนัก" : null,
                ),
              ),

              _buildInputBox(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _birthday == null
                        ? "วันเกิด"
                        : "${_birthday!.toLocal()}".split(" ")[0],
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _birthday ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _birthday = date);
                  },
                ),
              ),

              _buildInputBox(
                child: TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "หมายเหตุ",
                  ),
                  maxLines: 2,
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9966),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _saveCat,
                  child: const Text(
                    "บันทึก",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
