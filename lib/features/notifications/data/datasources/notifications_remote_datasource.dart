import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notification.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<AppNotification>> getUserNotifications(String userId);
  Future<void> saveNotification(AppNotification notification);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<int> getUnreadCount(String userId);
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  NotificationsRemoteDataSourceImpl(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('notifications');

  @override
  Future<List<AppNotification>> getUserNotifications(String userId) async {
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    return querySnapshot.docs.map(_fromDocument).toList();
  }

  @override
  Future<void> saveNotification(AppNotification notification) async {
    await _collection.doc(notification.id).set(_toMap(notification));
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _collection.doc(notificationId).update({'isRead': true});
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final batch = firestore.batch();
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    return querySnapshot.docs.length;
  }

  AppNotification _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return AppNotification(
      id: data['id'] as String,
      userId: data['userId'] as String,
      type: NotificationType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => NotificationType.expenseAdded,
      ),
      title: data['title'] as String,
      message: data['message'] as String,
      data: (data['data'] as Map<String, dynamic>?)?.cast<String, dynamic>(),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> _toMap(AppNotification notification) {
    return {
      'id': notification.id,
      'userId': notification.userId,
      'type': notification.type.name,
      'title': notification.title,
      'message': notification.message,
      'data': notification.data,
      'isRead': notification.isRead,
      'createdAt': Timestamp.fromDate(notification.createdAt),
    };
  }
}
