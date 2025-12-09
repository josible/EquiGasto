const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.onNotificationCreated = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot) => {
    const notification = snapshot.data();
    if (!notification) {
      return null;
    }

    const userId = notification.userId;
    if (!userId) {
      return null;
    }

    const userRef = admin.firestore().collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return null;
    }

    const tokens = userDoc.data().fcmTokens || [];
    if (!tokens.length) {
      return null;
    }

    // Estructura del payload para asegurar que las notificaciones se muestren
    // cuando la app está en background o cerrada
    const payload = {
      tokens,
      notification: {
        title: notification.title,
        body: notification.message,
      },
      data: {
        groupId: notification.data?.groupId ?? '',
        expenseId: notification.data?.expenseId ?? '',
        amount: String(notification.data?.amount ?? ''),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'expenses_updates',
          sound: 'default',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          tag: notification.data?.groupId ?? 'default',
          visibility: 'public',
          notificationCount: 1,
          icon: '@mipmap/ic_launcher',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            contentAvailable: true,
            alert: {
              title: notification.title,
              body: notification.message,
            },
          },
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(payload);

    const tokensToRemove = [];
    response.responses.forEach((res, index) => {
      if (!res.success) {
        const errorCode = res.error?.code ?? '';
        if (
          errorCode === 'messaging/invalid-registration-token' ||
          errorCode === 'messaging/registration-token-not-registered'
        ) {
          tokensToRemove.push(tokens[index]);
        }
      }
    });

    if (tokensToRemove.length) {
      await userRef.update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
      });
    }

    return null;
  });

