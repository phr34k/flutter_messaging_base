import 'package:flutter_messaging_base/model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:json_annotation/json_annotation.dart';
//part 'messages.g.dart';

extension MessageList on List<Message> {
  Message? lastWhereNull(bool Function(Message element) test) {
    final itt = where(test);
    return itt.isNotEmpty ? itt.last : null;
  }
}

/*

/// A class that represents text message.
@immutable
@JsonSerializable()
class SystemTextMessage extends CustomMessage {
  /// Creates a text message.
  const SystemTextMessage({
    required User author,
    int? createdAt,
    required String id,
    Map<String, dynamic>? metadata,
    String? remoteId,
    Message? repliedMessage,
    String? roomId,
    bool? showStatus,
    Status? status,
    int? updatedAt,
    MessageType? type,
    this.previewData,
    required this.text,
  }) : super(
          remoteId: remoteId,
          repliedMessage: repliedMessage,
          author: author,
          createdAt: createdAt,
          id: id,
          type: type,
          metadata: metadata,
          roomId: roomId,
          status: status,
          showStatus: showStatus,
          updatedAt: updatedAt,
        );

  /// Creates a full text message from a partial one.
  SystemTextMessage.fromPartial({
    required User author,
    int? createdAt,
    required String id,
    required PartialCustom partialCustom,
    String? remoteId,
    Message? repliedMessage,
    String? roomId,
    bool? showStatus,
    MessageType? type,
    Status? status,
    int? updatedAt,
    PreviewData? previewData,
    required String text,
  })  : previewData = previewData,
        text = text,
        super(
          remoteId: remoteId,
          repliedMessage: repliedMessage,
          author: author,
          createdAt: createdAt,
          id: id,
          type: type,
          metadata: partialCustom.metadata,
          roomId: roomId,
          status: status,
          showStatus: showStatus,
          updatedAt: updatedAt,
        );

  /// Creates a custom message from a map (decoded JSON).
  factory SystemTextMessage.fromJson(Map<String, dynamic> json) =>
      _$SystemTextMessageFromJson(json);

  /// Converts a text message to the map representation, encodable to JSON.
  @override
  Map<String, dynamic> toJson() => _$SystemTextMessageToJson(this);

  /// Creates a copy of the text message with an updated data
  /// [metadata] with null value will nullify existing metadata, otherwise
  /// both metadatas will be merged into one Map, where keys from a passed
  /// metadata will overwite keys from the previous one.
  /// [status] with null value will be overwritten by the previous status.
  /// [updatedAt] with null value will nullify existing value.
  @override
  Message copyWith({
    Map<String, dynamic>? metadata,
    PreviewData? previewData,
    String? remoteId,
    bool? showStatus,
    Status? status,
    String? text,
    int? updatedAt,
    String? uri,
  }) {
    return SystemTextMessage(
      author: author,
      createdAt: createdAt,
      id: id,
      metadata: metadata == null
          ? null
          : {
              ...this.metadata ?? {},
              ...metadata,
            },
      previewData: previewData,
      roomId: roomId,
      status: status ?? this.status,
      text: text ?? this.text,
      updatedAt: updatedAt,
    );
  }

  /// Equatable props
  @override
  List<Object?> get props => [
        author,
        createdAt,
        id,
        metadata,
        previewData,
        roomId,
        status,
        text,
        updatedAt,
      ];

  /// See [PreviewData]
  final PreviewData? previewData;

  /// User's message
  final String text;
}
*/