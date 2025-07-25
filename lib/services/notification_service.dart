import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:prado_negocios/services/auth_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AuthService _authService = AuthService();

  Future<void> init() async {
    // Pede permissão ao utilizador (importante para iOS)
    await _fcm.requestPermission();

    // Obtém o token FCM do dispositivo
    final token = await _fcm.getToken();
    print('FCM Token: $token');
    if (token != null) {
      _saveTokenToDatabase(token);
    }

    // Ouve por atualizações do token
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);

    // Configura as notificações locais para quando a aplicação está aberta
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(initializationSettings);

    // Ouve por mensagens recebidas
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  void _saveTokenToDatabase(String token) {
    // Esta função será chamada pelo AuthService para guardar o token
    // associado ao utilizador autenticado.
    _authService.saveUserToken(token);
  }

  // Mostra uma notificação quando a aplicação está em primeiro plano
  void _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'Este canal é usado para notificações importantes.',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformChannelSpecifics,
      );
    }
  }
}
