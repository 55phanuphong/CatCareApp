import 'package:flutter/material.dart';
import '../models/cat.dart';
import '../services/cat_service.dart';
import 'add_edit_cat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CatService _catService = CatService();

  Future<void> _confirmDelete(BuildContext context, Cat cat) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: Text("คุณต้องการลบแมว ${cat.name} ใช่หรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("ลบ"),
          ),
        ],
      ),
    );

    if (result == true) {
      await _catService.deleteCat(cat.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ลบแมว ${cat.name} แล้ว")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("รายชื่อแมว")),
      body: StreamBuilder<List<Cat>>(
        stream: _catService.getCats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final cats = snapshot.data!;
          if (cats.isEmpty) {
            return const Center(child: Text("ยังไม่มีแมว"));
          }

          return ListView.builder(
            itemCount: cats.length,
            itemBuilder: (context, index) {
              final cat = cats[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(cat.profileUrl),
                  child: null,
                ),
                title: Text(cat.name),
                subtitle: Text("น้ำหนัก: ${cat.weight} kg"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, cat),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditCatPage(cat: cat),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditCatPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
