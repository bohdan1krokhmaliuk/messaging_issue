import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

abstract class MessagingService {
  factory MessagingService() {
    _instance ??= MessagingServiceImpl();

    return _instance!;
  }
  static MessagingService? _instance;

  Stream<RemoteMessage> get appNotVisibleMessagesStream;
  Stream<RemoteMessage> get appVisibleMessagesStream;
  Future<void> initializeStreams();
  void dispose();
}

class MessagingServiceImpl implements MessagingService {
  final _backgroundMessageController =
      StreamController<RemoteMessage>.broadcast();

  @override
  Stream<RemoteMessage> get appNotVisibleMessagesStream =>
      _backgroundMessageController.stream;
  @override
  Stream<RemoteMessage> get appVisibleMessagesStream =>
      FirebaseMessaging.onMessage;

  @override
  Future<void> initializeStreams() async {
    await FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _backgroundMessageController.sink.add(message);
    });
    await _backgroundMessageController.sink.addStream(
      FirebaseMessaging.onMessageOpenedApp,
    );
  }

  @override
  void dispose() {
    _backgroundMessageController.close();
    MessagingService._instance = null;
  }
}
