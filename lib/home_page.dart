import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coretico_firebasenote/crud_service.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final CrudService service = CrudService();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Firebase Coretico'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ), // AppBar
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => openAddDialog(context),
      ), // FloatingActionButton
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No items found", style: TextStyle(fontSize: 18)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var item = docs[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    item['name'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ), // Text
                  subtitle: Text("Quantity ${item['quantity']}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ), // Text
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => openEditDialog(context, item),
                      ), // IconButton
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, item.id,)
                      ), // IconButton
                    ],
                  ), // Row
                ), // ListTile
              ); // Card
            }
          ); // ListView.builder
        }, // StreamBuilder
      ), // Scaffold
    );
  }

  //DELETE UI
  void _confirmDelete(BuildContext context, String id){
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete item"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              service.deleteItem(id);
              Navigator.pop(context);
            },
          ), // TextButton
        ],
      ) // AlertDialog
    );
  }

  //ADD UI
  void openAddDialog (BuildContext context) {
    nameCtrl.clear();
    qtyCtrl.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ), // InputDecoration
            ), // TextField
            SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Quantity",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ), // InputDecoration
            ), // TextField
          ],
        ), // Column
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ), // TextButton
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Save"),
            onPressed: () {
              if(nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty){
                service.addItem(nameCtrl.text, int.parse( qtyCtrl.text));
                Navigator.pop(context);
              }
            },
          ), // ElevatedButton
        ],
      ) // AlertDialog
    );
  }

  //EDIT UI
  void openEditDialog(BuildContext context, DocumentSnapshot item){
    nameCtrl.text = item['name'];
    qtyCtrl.text = item['quantity'].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ), // InputDecoration
            ), // TextField
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Quantity",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ), // InputDecoration
            ), // TextField
          ],
        ), // Column
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ), // TextButton
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Update"),
            onPressed: () {
              if(nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty){
                service.updateItem(item.id, nameCtrl.text, int.parse(qtyCtrl.text));
                Navigator.pop(context);
              }
            },
          ), // ElevatedButton
        ],
      ), // AlertDialog
    );
  }
}
