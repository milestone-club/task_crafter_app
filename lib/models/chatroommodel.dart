import 'package:task_crafter_app/models/messagemodel.dart';

class ChatRoomModel {
  String? chatroomid;
  List<String>? participants;
  List<MessageModel>? messages;

  ChatRoomModel({this.chatroomid, this.participants, this.messages});

  ChatRoomModel.fromMap(Map<String, dynamic> map) {
    chatroomid = map['chatroomid'];
    participants = List<String>.from(map['participants']);
    if (map['messages'] != null) {
      messages = (map['messages'] as List)
          .map((messageMap) => MessageModel.fromMap(messageMap))
          .toList();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'chatroomid': chatroomid,
      'participants': participants,
      'messages': messages?.map((message) => message.toMap()).toList(),
    };
  }
}
