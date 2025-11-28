import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coretico_firebasenote/crud_service.dart';
import 'package:coretico_firebasenote/auth_service.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CrudService service = CrudService();
  final AuthService authService = AuthService();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  bool showOnlyFavorites = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Firebase Lastname'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(
              showOnlyFavorites ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                showOnlyFavorites = !showOnlyFavorites;
              });
            },
            tooltip: showOnlyFavorites ? 'Show All' : 'Show Favorites Only',
          ),
          IconButton(
            icon: const Icon(Icons.key, color: Colors.white),
            onPressed: () => _showChangePasswordDialog(context),
            tooltip: 'Change Password',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _confirmSignOut(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => openAddDialog(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getItemsWithFavoriteFilter(onlyFavorites: showOnlyFavorites),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                showOnlyFavorites ? "No favorite items" : "No items found",
                style: const TextStyle(fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var item = docs[index];
              final data = item.data() as Map<String, dynamic>;
              final imageUrl = data['image_url'];
              
              // Safely get favorite field, default to false if it doesn't exist
              bool isFavorite = false;
              try {
                isFavorite = item['favorite'] ?? false;
              } catch (e) {
                isFavorite = false;
              }
              
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : null,
                  title: Text(
                    data['name'] ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Quantity ${data['quantity'] ?? 0}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          color: isFavorite ? Colors.amber : Colors.grey,
                        ),
                        onPressed: () {
                          service.toggleFavorite(item.id, isFavorite);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => openEditDialog(context, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, item.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // CHANGE PASSWORD DIALOG
  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Change Password"),
            onPressed: () async {
              if (currentPasswordCtrl.text.isEmpty || 
                  newPasswordCtrl.text.isEmpty || 
                  confirmPasswordCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              if (newPasswordCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }

              if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              final success = await authService.changePassword(
                currentPasswordCtrl.text,
                newPasswordCtrl.text,
              );

              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to change password. Check current password.'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // SIGN OUT CONFIRMATION
  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(context);
              await authService.signOut();
            },
          ),
        ],
      ),
    );
  }

  //DELETE UI
  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete item"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              service.deleteItem(id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  //ADD UI
  void openAddDialog(BuildContext context) {
    nameCtrl.clear();
    qtyCtrl.clear();

    File? selectedImageFile;
    String? selectedImageUrl;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              if (selectedImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    selectedImageUrl!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 0),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload Image"),
                onPressed: () async {
                  try {
                    final pickedImage = await service.pickImageForAddItem();
                    if (pickedImage != null) {
                      setState(() {
                        selectedImageFile = pickedImage.file;
                        selectedImageUrl = pickedImage.url;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image uploaded successfully!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to upload image: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Save"),
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                  await service.addItemWithImage(
                    nameCtrl.text,
                    int.parse(qtyCtrl.text),
                    selectedImageUrl,
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  //EDIT UI
  void openEditDialog(BuildContext context, DocumentSnapshot item) {
    nameCtrl.text = item['name'];
    qtyCtrl.text = item['quantity'].toString();

    String? currentImageUrl = item['image_url'];
    String? selectedImageUrl = currentImageUrl;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Edit item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              if (selectedImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    selectedImageUrl!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 0),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text("Change Image"),
                onPressed: () async {
                  try {
                    final pickedImage = await service.pickImageForAddItem();
                    if (pickedImage != null) {
                      setState(() {
                        selectedImageUrl = pickedImage.url;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image uploaded successfully!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to upload image: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Update"),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                  service.updateItemWithImage(item.id, nameCtrl.text, int.parse(qtyCtrl.text), selectedImageUrl);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}