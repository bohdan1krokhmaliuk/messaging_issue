// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart=2.9

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'firebase_messaging_bloc.dart';
import 'message.dart';
import 'message_list.dart';
import 'permissions.dart';
import 'token_monitor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(MessagingExampleApp());
}

/// Entry point for the example application.
class MessagingExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messaging Example App',
      theme: ThemeData.dark(),
      routes: {
        '/': (context) => Application(),
        '/message': (context) => MessageView(),
      },
    );
  }
}

// Crude counter to make messages unique
int _messageCount = 0;

/// The API endpoint here accepts a raw FCM payload for demonstration purposes.
String constructFCMPayload(String token) {
  _messageCount++;
  return jsonEncode({
    'to': token,
    'notification': {
      'title': 'Hello FlutterFire!',
      'body': 'This notification (#$_messageCount) was created via FCM!',
    },
    'android': {
      'priority': 'high',
      'notification': {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      }
    },
    'data': {
      'via': 'FlutterFire Cloud Messaging!!!',
      'count': _messageCount.toString(),
    }
  });
}

/// Renders the example application.
class Application extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _Application();
}

class _Application extends State<Application> {
  MessagingService service;
  String _token;

  @override
  void initState() {
    super.initState();
    _intializeMessaging();
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Messaging'),
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: sendPushMessage,
          backgroundColor: Colors.white,
          child: const Icon(Icons.send),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          MetaCard('Permissions', Permissions()),
          MetaCard('FCM Token', TokenMonitor((token) {
            _token = token;
            return token == null
                ? const CircularProgressIndicator()
                : Text(token, style: const TextStyle(fontSize: 12));
          })),
          MetaCard('Message Stream', MessageList(service: service)),
        ]),
      ),
    );
  }

  Future<void> sendPushMessage() async {
    if (_token == null) {
      print('Unable to send FCM message, no token exists.');
      return;
    }

    await Future.delayed(const Duration(seconds: 2));

    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization':
              'key=AAAAC8Ths74:APA91bHUPPlOKFovHdCz0pY--mkWpL8MfvGvT43HJRcugcJdqh67UlQ1uxUS767QWKa-17xhIXcV_oKHNNXg0ff21MoVYaGP1vB8yUBVeVGew8EiGIihzk2jfgcxrLKINSI5aMR-HwQ5',
        },
        body: constructFCMPayload(_token),
      );
      print('FCM request for device sent!');
    } catch (e) {
      print(e);
    }
  }

  Future<void> _intializeMessaging() async {
    service = MessagingService();
    // FirebaseMessaging.instance.getInitialMessage().then((message) {
    //   if (message == null) return;
    //   Navigator.pushNamed(
    //     context,
    //     '/message',
    //     arguments: MessageArguments(message, true),
    //   );
    // });

    service.appNotVisibleMessagesStream.listen((RemoteMessage message) {
      Navigator.pushNamed(
        context,
        '/message',
        arguments: MessageArguments(message, true),
      );
    });

    /// Initialize streams after starting listening to appNotVisibleMessagesStream
    /// in order to be sure that FirebaseMessaging.instance.getInitialMessage will be
    /// executed later than bloc.appNotVisibleMessagesStream.listen method.
    await service.initializeStreams();
  }
}

/// UI Widget for displaying metadata.
class MetaCard extends StatelessWidget {
  final String _title;
  final Widget _children;

  // ignore: public_member_api_docs
  MetaCard(this._title, this._children);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Text(_title, style: const TextStyle(fontSize: 18)),
            ),
            _children,
          ]),
        ),
      ),
    );
  }
}
