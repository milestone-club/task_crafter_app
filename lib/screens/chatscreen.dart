// ignore_for_file: unnecessary_null_comparison, library_private_types_in_public_api, unnecessary_brace_in_string_interps, avoid_print, avoid_function_literals_in_foreach_calls, non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:task_crafter_app/push_notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String deviceToken;

  const ChatScreen({super.key, 
    required this.recipientId,
    required this.recipientName,
    required this.deviceToken,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  late DocumentReference<Map<String, dynamic>> _chatRoomDocument;
  String? currentUserName;

  @override
  void initState() {
    super.initState();
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    String chatRoomId = getChatRoomId(currentUserId, widget.recipientId);
    _chatRoomDocument =
        FirebaseFirestore.instance.collection('chatrooms').doc(chatRoomId);
    _createChatRoomIfNotExists();

    // Mark messages as seen when opening the chat
    _markMessagesAsSeen();

    // Fetch current user name
    _fetchCurrentUserName();
  }

  String getChatRoomId(String user1, String user2) {
    return user1.compareTo(user2) > 0 ? '${user1}$user2' : '${user2}$user1';
  }

  Future<void> _createChatRoomIfNotExists() async {
    try {
      DocumentSnapshot doc = await _chatRoomDocument.get();
      if (!doc.exists) {
        await _chatRoomDocument.set({
          'chatroomid': _chatRoomDocument.id,
          'participants': [
            FirebaseAuth.instance.currentUser!.uid,
            widget.recipientId
          ],
        });
      }
    } catch (e) {
      print('Error creating chat room: $e');
    }
  }

  Future<void> _fetchCurrentUserName() async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('profiles')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        setState(() {
          currentUserName = userDoc.data()?['firstName'];
        });
      }
    } catch (e) {
      print('Error fetching current user name: $e');
    }
  }

  Future<void> sendMessage(String message, {String? fileUrl}) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final newMessage = MessageModel(
      messageid: _chatRoomDocument.collection('messages').doc().id,
      sender: currentUserId,
      text: message,
      fileUrl: fileUrl,
      seen: false,
      createdon: DateTime.now(),
    );

    try {
      await _chatRoomDocument
          .collection('messages')
          .doc(newMessage.messageid)
          .set(newMessage.toMap());
      messageController.clear();

      // Send push notification with current user's name
      await PushNotificationService.sendNotification(
        widget.deviceToken,
        'New message from ${currentUserName ?? 'someone'}',
        message,
      );
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> _markMessagesAsSeen() async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot messagesSnapshot =
        await _chatRoomDocument.collection('messages').get();
    WriteBatch batch = FirebaseFirestore.instance.batch();

    messagesSnapshot.docs.forEach((doc) {
      if (doc['sender'] != currentUserId && !doc['seen']) {
        batch.update(doc.reference, {'seen': true});
      }
    });

    try {
      await batch.commit();
    } catch (e) {
      print('Error marking messages as seen: $e');
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      PlatformFile file = result.files.first;
      await _uploadFile(file);
    }
  }

  Future<void> _uploadFile(PlatformFile file) async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      Reference storageReference = FirebaseStorage.instanceFor(
              bucket: 'gs://taskcrafter-a7c64.appspot.com')
          .ref()
          .child('chat_files/$currentUserId/${file.name}');
      UploadTask uploadTask = storageReference.putFile(File(file.path!));
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
      String fileUrl = await taskSnapshot.ref.getDownloadURL();
      sendMessage(file.name, fileUrl: fileUrl);
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  Future openFile(String fileUrl, String? fileName) async {
    final file = await _downloadFile(fileUrl, fileName!);
    if (file == null) return;
    print('Path: ${file.path}');
    OpenFile.open(file.path);
  }

  Future<File> _downloadFile(String fileUrl, String fileName) async {
    final appStorage = await getExternalStorageDirectory();
    final file = File('${appStorage!.path}/$fileName');

    final Response = await Dio().get(
      fileUrl,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        receiveTimeout: 0.seconds,
      ),
    );
    final raf = file.openSync(mode: FileMode.write);
    raf.writeFromSync(Response.data);
    await raf.close();
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatRoomDocument
                  .collection('messages')
                  .orderBy('createdon', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet.'),
                  );
                }

                List<MessageModel> messages = snapshot.data!.docs
                    .map((doc) => MessageModel.fromMap(
                        doc.data() as Map<String, dynamic>))
                    .toList();

                DateTime? currentDate;
                bool isFirstMessage = true;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isMe = message.sender ==
                        FirebaseAuth.instance.currentUser!.uid;

                    final String time =
                        '${message.createdon!.hour}:${message.createdon!.minute.toString().padLeft(2, '0')}';

                    if (currentDate == null ||
                        currentDate?.day != message.createdon!.day) {
                      currentDate = message.createdon;
                      if (!isFirstMessage) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              '${message.createdon!.day}/${message.createdon!.month}/${message.createdon!.year}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _buildMessageBubble(message, isMe, time),
                          ],
                        );
                      } else {
                        isFirstMessage = false;
                      }
                    }

                    return _buildMessageBubble(message, isMe, time);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickFile,
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      String message = messageController.text.trim();
                      if (message.isNotEmpty) {
                        sendMessage(message);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.text != null)
              Text(
                message.text!,
                style: const TextStyle(fontSize: 16),
              ),
            if (message.fileUrl != null)
              InkWell(
                onTap: () => openFile(message.fileUrl!, message.text!),
                child: Row(
                  children: [
                    const Icon(Icons.download),
                    Text(message.text!),
                  ],
                ),
              ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 5),
                  Icon(
                    message.seen! ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.seen! ? Colors.blue : Colors.grey,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ChatRoomModel class
class ChatRoomModel {
  String? chatroomid;
  List<String>? participants;
  List<MessageModel>? messages;

  ChatRoomModel({this.chatroomid, this.participants, this.messages});

  ChatRoomModel.fromMap(Map<String, dynamic> map) {
    chatroomid = map['chatroomid'];
    participants = List<String>.from(map['participants']);
    messages = (map['messages'] as List)
        .map((message) => MessageModel.fromMap(message))
        .toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'chatroomid': chatroomid,
      'participants': participants,
    };
  }
}

// MessageModel class
class MessageModel {
  String? messageid;
  String? sender;
  String? text;
  String? fileUrl;
  bool? seen;
  DateTime? createdon;

  MessageModel({
    this.messageid,
    this.sender,
    this.text,
    this.fileUrl,
    this.seen,
    this.createdon,
  });

  MessageModel.fromMap(Map<String, dynamic> map) {
    messageid = map['messageid'];
    sender = map['sender'];
    text = map['text'];
    fileUrl = map['fileUrl'];
    seen = map['seen'];
    createdon = (map['createdon'] as Timestamp).toDate();
  }

  Map<String, dynamic> toMap() {
    return {
      'messageid': messageid,
      'sender': sender,
      'text': text,
      'fileUrl': fileUrl,
      'seen': seen,
      'createdon': createdon,
    };
  }
}
