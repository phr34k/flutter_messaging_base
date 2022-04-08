// ignore_for_file: unused_import

import 'dart:async';
import 'dart:collection';

import 'package:flutter_messaging_base/widgets/chatpage.dart';
import 'package:flutter_messaging_base/widgets/inboxpage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';

class Conversation {
  final String uuid;
  final int? unread;
  final int? status;
  final List<types.Message>? messsages;
  Conversation(this.uuid, {this.unread, this.status, this.messsages});
}

/*
class Message {
  final String text;
  Message(this.text);
}

class Event {
  final int type;
  Event(this.type);
}
*/

abstract class Persistance {
  void clear();
}

abstract class SDK {
  final bool showUserAvatars;
  final bool showUserNames;
  final DateFormat? timeFormat;
  final DateFormat? dateFormat;
  final WidgetBuilder? conversationBuilder;
  final WidgetBuilder? inboxBuilder;

  SDK(
      {this.showUserAvatars = true,
      this.showUserNames = true,
      this.timeFormat,
      this.dateFormat,
      this.conversationBuilder,
      this.inboxBuilder});

  types.User get author;
  final StreamController<Conversation> _conversationController =
      StreamController<Conversation>.broadcast();
  List<types.Message> messages = [];
  List<Conversation> conversations = [];

  void notifyInboxChanged() {
    _conversationController.add(Conversation("test"));
  }

  Future<List<Conversation>> conversation() {
    var list = conversations
        .map((e) => Conversation(e.uuid, unread: e.unread, messsages: []))
        .toList();
    for (var element in list) {
      element.messsages?.add(messages.first);
      element.messsages?.add(messages.last);
    }

    return Future.value(list);
  }

  Future<Conversation> create();

  Future<bool> getStatus({required String? conversationId});

  Future<List<types.Message>> getMessages({required String? conversationId}) {
    return Future.value(
        messages.where((element) => element.roomId == conversationId).toList());
  }

  Stream<Conversation> get conversationUpdates =>
      _conversationController.stream;

  Future<String> newConversationId();
  Future<String> newMessageId();

  void updateMessage(types.Message message) {
    var matchingConversations =
        conversations.where((element) => element.uuid == message.roomId);
    if (matchingConversations.isEmpty) {
      var conv = matchingConversations.first;
      conversations.remove(conv);
      conversations.add(Conversation(conv.uuid,
          unread: messages
              .where((element) =>
                  element.roomId == message.roomId &&
                  element.author != element.author &&
                  element.status!.index < types.Status.seen.index)
              .length,
          messsages: conv.messsages));
      _conversationController.add(matchingConversations.first);
    }
  }

  void addMessage(types.Message message);

  void setConversationResolved(String conversationId);
  void setConversationOpened(String conversationId);
  //get the persitance provider that belongs to the sdk
  Persistance getPersistances();
  bool get enablePersistence;

  //get the conversation provider that belongs to the sdk
  ConversationProvider getConversationProvider({String? conversationId});
  //get the inbox provider that belongs to the sdk
  InboxProvider getInboxProvider();
  //get the chat theme that belongs to the sdk
  ChatTheme getTheme();
  //get the l10n strings that belong to the sdk
  ChatL10n getl10n();

  //get the material page route for the inbox
  MaterialPageRoute getInboxRoute({required WidgetBuilder pageBuilder}) {
    return MaterialPageRoute(
      builder: (_) => Provider<InboxProvider>(
          create: (_) {
            //var inbox = Provider.of<InboxProvider>(_, listen: false);
            return getInboxProvider();
          },
          child: pageBuilder(_)),
    );
  }

  //get the conversation page route for the conversation
  MaterialPageRoute getConversationRoute(
      {required String? conversationId, required WidgetBuilder pageBuilder}) {
    return MaterialPageRoute(
      builder: (_) => Provider<ConversationProvider>(
          create: (_) {
            //var inbox = Provider.of<InboxProvider>(_, listen: false);
            return getConversationProvider(conversationId: conversationId);
          },
          child: pageBuilder(_)),
    );
  }

  //get the material page route for the inbox using the default ui
  MaterialPageRoute getDefaultConversationUI(
      {required String? conversationId}) {
    return getConversationRoute(
        conversationId: conversationId,
        pageBuilder:
            conversationBuilder ?? (_) => const ChatPage(title: 'test'));
  }

  //get the material page route for the conversation using the default ui
  MaterialPageRoute getDefaultInboxUI() {
    return getInboxRoute(
        pageBuilder: inboxBuilder ?? (_) => const InboxPage(title: 'test'));
  }
}

class InboxProvider {
  final SDK sdk;
  InboxProvider(this.sdk);

  Stream<List<Conversation>> get messages {
    var subject = BehaviorSubject<Conversation>.seeded(Conversation(""));
    subject.addStream(sdk.conversationUpdates);
    return subject.stream.asyncMap((event) => sdk.conversation());
  }

  Future<Conversation> create() => sdk.create();
}

class MessageCollection<T> extends ChangeNotifier {
  final List<T> _messages = [];
  UnmodifiableListView<T> get collection => UnmodifiableListView(_messages);

  int indexWhere(bool Function(T element) test, [int start = 0]) {
    return indexWhere(test, start);
  }

  void replaceAll(Iterable<T> iterable) {
    _messages.clear();
    _messages.addAll(iterable);
    notifyListeners();
  }

  void addAll(Iterable<T> iterable) {
    _messages.addAll(iterable);
    notifyListeners();
  }

  void clear() {
    _messages.clear();
    notifyListeners();
  }

  void add(T updateMessage) {
    _messages.add(updateMessage);
    notifyListeners();
  }

  void insert(int index, T message) {
    _messages.insert(index, message);
    notifyListeners();
  }

  void replace(int index, T updateMessage) {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _messages[index] = updateMessage;
      notifyListeners();
    });
  }
}

abstract class ConversationProvider {
  SDK get sdk;
  types.User get author;
  List<types.Message> get messages;
  Listenable get changes;

  Stream get errors;
  ValueListenable<bool> get online;
  ValueListenable<bool> get typing;
  ValueListenable<bool> get status;
  ValueListenable<bool> get canReply;
  Future<bool> get loaded;

  Future<String> getConversationId();
  Future<String> newMessageId();

  //user marks the conversation as resolved
  Future<void> resolve();
  //user checks for more messages (infinity scrolling)
  Future<void> more();

  void resendMessage(types.Message message);
  void updateMessage(types.Message message, types.PreviewData previewData);
  void sendMessage(types.Message message);
  void beginTyping();
  void endTyping();
}
