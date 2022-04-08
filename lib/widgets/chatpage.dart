import 'dart:async';

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:mime/mime.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

import 'chat.dart';
import '../sdk.dart';
import '../model.dart' as types;

class ChatPage extends StatefulWidget {
  final String title;
  final double? onEndReachedThreshold;

  const ChatPage({Key? key, required this.title, this.onEndReachedThreshold})
      : super(key: key);

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  Timer? _timer;
  bool _showBottom = false;
  Listenable messageChangedOrTyping = Listenable.merge([]);

  void waitForMessages(ConversationProvider conv) async {
    print("wait for messages");
    await conv.loaded;

    if (conv.messages.isNotEmpty) {
      var s = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(
              conv.messages.first.createdAt!))
          .inMinutes;
      print("$s");
      _showBottom = conv.status.value && s > 60 * 60 * 24;
    }
    //_showBottom = false;
  }

  @override
  void initState() {
    super.initState();

    var conv = Provider.of<ConversationProvider>(context, listen: false);
    messageChangedOrTyping = Listenable.merge([conv.typing, conv.changes]);
    waitForMessages(conv);
  }

  Future<void> handleOnEndReached() {
    return Future.delayed(const Duration(seconds: 5));
  }

  void handleAtachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            height: 144,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    handleImageSelection();
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Photo'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    handleFileSelection();
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('File'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    var conv = Provider.of<ConversationProvider>(context, listen: false);
    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        roomId: await conv.getConversationId(),
        author: conv.author,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: await conv.newMessageId(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      conv.sendMessage(message);
    }
  }

  void handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    var conv = Provider.of<ConversationProvider>(context, listen: false);
    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        roomId: await conv.getConversationId(),
        author: conv.author,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: await conv.newMessageId(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      conv.sendMessage(message);
    }
  }

  void handleMessageLongPress(
      BuildContext context, types.Message message) async {
    /*
    if (message is types.FileMessage) {
      await OpenFile.open(message.uri);
    }
    */
  }

  void handleMessageTap(BuildContext context, types.Message message) async {
    if (message is types.FileMessage) {
      await OpenFile.open(message.uri);
    }
  }

  void handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    Provider.of<ConversationProvider>(context, listen: false)
        .updateMessage(message, previewData);
  }

  void handleSendPressed(types.PartialText message) async {
    var conv = Provider.of<ConversationProvider>(context, listen: false);
    final textMessage = types.TextMessage(
      roomId: await conv.getConversationId(),
      author: conv.author,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: await conv.newMessageId(),
      text: message.text,
    );

    conv.sendMessage(textMessage);
  }

  void handleTextChanged(String text) {
    var conv = Provider.of<ConversationProvider>(context, listen: false);
    conv.beginTyping();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _.cancel();
      conv.endTyping();
    });
  }

/*
  void _loadMessages() async {
    final response = await rootBundle.loadString('assets/messages.json');
    final messages = (jsonDecode(response) as List)
        .map((e) => types.Message.fromJson(e as Map<String, dynamic>))
        .toList();

    setState(() {
      _messages = messages;
    });
  }
*/

  Widget buildChatBody(BuildContext context, ConversationProvider conv) {
    return Chat(
      theme: conv.sdk.getTheme(),
      l10n: conv.sdk.getl10n(),
      messages: conv.messages.reversed.toList(),
      onAttachmentPressed: handleAtachmentPressed,
      onMessageStatusTap: handleMessageTap,
      onPreviewDataFetched: handlePreviewDataFetched,
      onSendPressed: handleSendPressed,
      user: conv.author,
      onEndReached: conv.more,
      onEndReachedThreshold: widget.onEndReachedThreshold,
      onMessageLongPress: handleMessageLongPress,
      onTextChanged: handleTextChanged,
      showUserAvatars: conv.sdk.showUserAvatars,
      showUserNames: conv.sdk.showUserNames,
      timeFormat: conv.sdk.timeFormat ?? DateFormat.Hm(),
      dateFormat: conv.sdk.timeFormat ?? DateFormat("EEEE MMMM d"),
    );
  }

  Widget buildTitle(BuildContext context, types.Message? title) {
    return title != null
        ? Text("Chat with ${title!.author.firstName}")
        : const Text("New conversation");
  }

  Widget buildBottomSheet(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
            height: 104,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.blue[100]),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text('Did we solve your issue?',
                      textAlign: TextAlign.left),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showBottom = false;
                            });
                          },
                          child: const Text('No, continue')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                          onPressed: () {
                            var conv = Provider.of<ConversationProvider>(
                                context,
                                listen: false);
                            setState(() {
                              _showBottom = false;
                              conv.resolve().then((value) {});
                            });
                          },
                          child: const Text('Yes, thanks')),
                    ],
                  )
                ],
              ),
            )));
  }

  Widget buildTitleEx(
      BuildContext context, ConversationProvider conv, types.Message? title) {
    return Row(
      children: [
        AnimatedBuilder(
            animation: conv.online,
            builder: (_, __) => Badge(
                  badgeContent: null,
                  badgeColor: conv.online.value ? Colors.lime : Colors.red,
                  position: BadgePosition.bottomEnd(bottom: -0, end: -0),
                  child: CircleAvatar(
                    backgroundImage: title?.author.imageUrl != null
                        ? NetworkImage(title!.author.imageUrl!)
                        : null,
                    backgroundColor: Colors.lightBlue,
                    radius: 16.0,
                  ),
                )),
        SizedBox(width: 8),
        buildTitle(context, title),
        /*
,*/
      ],
    );
  }

  Widget buildTypingNotification(BuildContext context) {
    return Positioned(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                  color: Colors.blue[100]),
              width: 300,
              child: const Padding(
                  padding: EdgeInsets.all(8.0), child: Text("is typing...")),
            )
          ],
        ),
        left: 20,
        right: 20,
        height: 40,
        bottom: 80);
  }

  Widget buildBanner(BuildContext context) {
    var conv = Provider.of<ConversationProvider>(context, listen: true);
    return Material(
        elevation: 8,
        child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              if (conv.status.value == false)
                Icon(Icons.check_circle, color: Colors.green),
              if (conv.status.value == false) SizedBox(width: 8),
              Text(
                conv.status.value ? "open" : "resolved",
                textAlign: TextAlign.left,
              )
            ])));
  }

  PreferredSizeWidget buildAppBar(BuildContext context) {
    var conv = Provider.of<ConversationProvider>(context, listen: true);
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: AnimatedBuilder(
          animation: conv.changes,
          builder: (_, __) {
            return buildTitleEx(
                context,
                conv,
                conv.messages
                    .lastWhereNull((element) => element.author != conv.author));
          }),
    );
  }

  Widget buildLoading(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Center(child: CircularProgressIndicator())]);
  }

  @override
  Widget build(BuildContext context) {
    var conv = Provider.of<ConversationProvider>(context, listen: true);
    return FutureBuilder(
        future: conv.loaded,
        builder: (_, __) {
          if (__.connectionState == ConnectionState.waiting ||
              __.connectionState == ConnectionState.none)
            return Scaffold(body: buildLoading(context));
          return AnimatedBuilder(
              animation: Listenable.merge([conv.status, conv.canReply]),
              builder: (_, __) => Scaffold(
                    appBar: buildAppBar(context),
                    bottomSheet:
                        _showBottom == true ? buildBottomSheet(context) : null,
                    body: Column(
                      children: [
                        buildBanner(context),
                        Expanded(
                            child: AnimatedBuilder(
                                animation: messageChangedOrTyping,
                                builder: (_, __) {
                                  return Stack(children: [
                                    buildChatBody(context, conv),
                                    if (conv.typing.value == true)
                                      buildTypingNotification(context)
                                  ]);
                                }))
                      ],
                    ),

                    /*
        body: StreamBuilder<types.Message>(
            builder: (context, snapshot) {
              
            },
            stream: conv.notifications)
            */
                  ));
        });
  }
}
