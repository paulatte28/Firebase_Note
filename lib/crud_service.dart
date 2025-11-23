import 'package:cloud_firestore/cloud_firestore.dart';

class CrudService {
  final CollectionReference items =
      FirebaseFirestore.instance.collection('items');

  Future<void> addItem(String name, int quantity) {
    //CREATE
    return items.add({
      'name': name,
      'quantity': quantity,
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
      return items.where('favorite', isEqualTo: true).orderBy('createdAt', descending: true).snapshots();
    }
    return getItems();
  }

  //UPDATE
  Future<void> updateItem(String id, String name, int quantity, {bool? favorite}) {
    Map<String, dynamic> updateData = {
      'name': name,
      'quantity': quantity,
    };
    if (favorite != null) {
      updateData['favorite'] = favorite;
    }
    return items.doc(id).update(updateData);
  }

  Future<void> toggleFavorite(String id, bool currentFavorite) {
    return items.doc(id).update({'favorite': !currentFavorite});
  }

  //DELETE
  Future<void> deleteItem(String id) {
    return items.doc(id).delete();
  }
}
