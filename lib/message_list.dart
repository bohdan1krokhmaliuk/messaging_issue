// @dart=2.9

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_messaging_bloc.dart';
import 'message.dart';

extension RemoteMessageExt on RemoteMessage {
  RemoteMessage copyWith(final String category) {
    return RemoteMessage(
        senderId: senderId,
        category: category,
        collapseKey: collapseKey,
        contentAvailable: contentAvailable,
        data: data,
        from: from,
        messageId: messageId,
        messageType: messageType,
        mutableContent: mutableContent,
        notification: notification,
        sentTime: sentTime,
        threadId: threadId,
        ttl: ttl);
  }
}

/// Listens for incoming foreground messages and displays them in a list.
class MessageList extends StatefulWidget {
  const MessageList({Key key, @required this.service}) : super(key: key);

  final MessagingService service;

  @override
  State<StatefulWidget> createState() => _MessageList();
}

class _MessageList extends State<MessageList> {
  List<RemoteMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    widget.service.appNotVisibleMessagesStream.listen(
      (message) => _streamListener(message, 'background message'),
    );
    widget.service.appVisibleMessagesStream.listen(
      (message) => _streamListener(message, 'foreground message'),
    );
  }

  void _streamListener(RemoteMessage message, String category) {
    if (mounted) {
      setState(() => _messages = [..._messages, message.copyWith(category)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_messages.isEmpty) return const Text('No messages received');

    return ListView.builder(
        shrinkWrap: true,
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          RemoteMessage message = _messages[index];

          return ListTile(
            title: Text(message.messageId),
            trailing: Text(message.category ?? 'N/A'),
            subtitle: Text(message.sentTime?.toString() ?? 'N/A'),
            onTap: () => Navigator.pushNamed(context, '/message',
                arguments: MessageArguments(message, false)),
          );
        });
  }
}
