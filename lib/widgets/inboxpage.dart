import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';

import '../sdk.dart';
import '../model.dart' as types;

class InboxPage extends StatefulWidget {
  const InboxPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  InboxPagetate createState() => InboxPagetate();
}

class InboxPagetate extends State<InboxPage> {
  Widget tile(BuildContext context, Conversation conversation) {
    var messages = conversation.messsages!.where((e) => e.author.id != "bot");
    types.Message? message = messages.isNotEmpty ? messages.last : null;

    return ListTile(
      leading: CircleAvatar(
          backgroundColor: conversation.status == 1
              ? Colors.grey.shade200
              : Colors.grey.shade200,
          maxRadius: 24,
          child: Padding(
              padding: EdgeInsets.all(8.0),
              child: conversation.status == 1
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : Icon(FontAwesomeIcons.solidComments))),
      trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text("${conversation.unread!}"),
        if (conversation.messsages!.isNotEmpty)
          Text(DateFormat('MMM d').format(DateTime.fromMillisecondsSinceEpoch(
              conversation.messsages!.last.createdAt!)))
      ]),
      title: Text(message == null
          ? "Chat with"
          : "Chat with ${message!.author.firstName} ${message!.author.lastName}"),
      subtitle: message == null
          ? null
          : Text(
              (message as types.TextMessage).text,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
      onTap: () {
        showChat(conversationId: conversation.uuid);
      },
    );
  }

  PreferredSizeWidget buildAppbar(BuildContext context) {
    return AppBar(
        title: Text(widget.title),
        systemOverlayStyle: SystemUiOverlayStyle.dark);
  }

  Widget buildLoading(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [Center(child: CircularProgressIndicator())]);
  }

  Widget buildEmpty(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [Center(child: Text('nothing to see here'))]);
  }

  Widget buildBody(BuildContext context) {
    var inboxProvider = Provider.of<InboxProvider>(context);
    return StreamBuilder<List<Conversation>>(
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return buildLoading(context);
          }

          var active = snapshot.data!.where((e) => e.status == 0).toList();
          var resolved = snapshot.data!.where((e) => e.status == 1).toList();

          if (active.isNotEmpty && resolved.isNotEmpty) {
            return Column(children: [
              const Padding(padding: EdgeInsets.all(20), child: Text('Active')),
              ListView.builder(
                shrinkWrap: true,
                itemBuilder: (_, __) => tile(context, active[__]),
                itemCount: active.length,
              ),
              const Padding(
                  padding: EdgeInsets.all(20), child: Text('Resolved')),
              ListView.builder(
                shrinkWrap: true,
                itemBuilder: (_, __) => tile(context, resolved[__]),
                itemCount: resolved.length,
              ),
            ]);
          } else if (active.isNotEmpty) {
            return Column(children: [
              const Padding(padding: EdgeInsets.all(20), child: Text('Active')),
              ListView.builder(
                shrinkWrap: true,
                itemBuilder: (_, __) => tile(context, active[__]),
                itemCount: active.length,
              )
            ]);
          } else if (resolved.isNotEmpty) {
            return Column(children: [
              const Padding(
                  padding: EdgeInsets.all(20), child: Text('Resolved')),
              ListView.builder(
                shrinkWrap: true,
                itemBuilder: (_, __) => tile(context, resolved[__]),
                itemCount: resolved.length,
              )
            ]);
          } else {
            return buildEmpty(context);
          }
        },
        //stream: inboxProvider.messages.map<List<types.Message>>(
        //    (event) => inboxProvider.getConversations(event))),

        stream: inboxProvider.messages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: buildAppbar(context),
        floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              showChat();
            }),
        body: buildBody(context));
  }

  void showChat({String? conversationId}) {
    var inboxProvider = Provider.of<InboxProvider>(context, listen: false);
    Navigator.of(context).push(inboxProvider.sdk
        .getDefaultConversationUI(conversationId: conversationId));
  }
}
