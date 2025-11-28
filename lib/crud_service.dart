import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class PickedImage {
  final File file;
  final String url;
  PickedImage({required this.file, required this.url});
}

class CrudService {
  final CollectionReference items =
      FirebaseFirestore.instance.collection('items');

  // Replace 'your_upload_preset' with your actual unsigned upload preset name
  // You can find this in Cloudinary Dashboard > Settings > Upload > Upload presets
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dtklmbgad',  // Your cloud name
    'notes_app',  // CHANGE THIS to your unsigned preset name
    cache: false,
  );

  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery and upload to Cloudinary
  Future<PickedImage?> pickImageForAddItem() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return null;

      final file = File(pickedFile.path);

      print('Uploading image to Cloudinary...');
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      print('Upload successful: ${response.secureUrl}');
      return PickedImage(file: file, url: response.secureUrl);
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Migration method to add favorite field to existing documents
  Future<void> migrateExistingItems() async {
    try {
      final snapshot = await items.get();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && !data.containsKey('favorite')) {
          await items.doc(doc.id).update({'favorite': false});
        }
      }
    } catch (e) {
      print('Migration error: $e');
    }
  }

  //CREATE
  Future<void> addItemWithImage(String name, int quantity, String? imageUrl) async {
    await items.add({
      'name': name,
      'quantity': quantity,
      'image_url': imageUrl,
      'favorite': false,
      'createdAt': Timestamp.now(),
    });
  }

  //READ
  Stream<QuerySnapshot> getItems() {
    return items.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot> getItemsWithFavoriteFilter({bool onlyFavorites = false}) {
    if (onlyFavorites) {
      return items
          .where('favorite', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    return getItems();
  }

  //UPDATE
  Future<void> updateItem(String id, String name, int quantity) {
    return items.doc(id).update({
      'name': name,
      'quantity': quantity,
    });
  }

  Future<void> updateItemWithImage(String id, String name, int quantity, String? imageUrl) {
    return items.doc(id).update({
      'name': name,
      'quantity': quantity,
      'image_url': imageUrl,
    });
  }

  Future<void> toggleFavorite(String id, bool currentFavorite) {
    return items.doc(id).update({'favorite': !currentFavorite});
  }

  //DELETE
  Future<void> deleteItem(String id) {
    return items.doc(id).delete();
  }
}