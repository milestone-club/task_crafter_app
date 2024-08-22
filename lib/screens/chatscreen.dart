import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:task_crafter_app/push_notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String deviceToken;

  ChatScreen({
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

    final response = await Dio().get(
      fileUrl,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        receiveTimeout: 0.seconds,
      ),
    );
    final raf = file.openSync(mode: FileMode.write);
    raf.writeFromSync(response.data);
    await raf.close();
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recipientName,
          style: TextStyle(
              color: const Color.fromARGB(
                  255, 7, 7, 7)), // Set AppBar text color to white
        ),
        backgroundColor:
            Color.fromARGB(255, 251, 247, 247), // Set AppBar color to blue
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/chat-background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
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
                    return Center(
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
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                              SizedBox(height: 10),
                              Text(
                                '${message.createdon!.day}/${message.createdon!.month}/${message.createdon!.year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      const Color.fromARGB(255, 132, 131, 131),
                                ),
                              ),
                              SizedBox(height: 5),
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
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color.fromARGB(255, 162, 146,
                        236), // Set attachment icon background color to blue
                    child: IconButton(
                      icon: Icon(Icons.attach_file,
                          color: Colors.white), // Set icon color to white
                      onPressed: _pickFile,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        filled: true,
                        fillColor:
                            Color.fromARGB(255, 162, 146, 236).withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 15),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Color.fromARGB(255, 162, 146,
                        236), // Set send button background color to blue
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
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
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe, String time) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Text(widget.recipientName[0]),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? Color.fromARGB(255, 162, 146, 236)
                    : Color.fromARGB(199, 243, 205, 229),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (message.fileUrl != null)
                    GestureDetector(
                      onTap: () => openFile(message.fileUrl!, message.text),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (message.fileUrl == null)
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(255, 36, 36, 36),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 5),
                    Icon(
                      message.seen! ? Icons.done_all : Icons.done,
                      size: 16,
                      color: message.seen!
                          ? const Color.fromARGB(255, 37, 129, 204)
                          : Color.fromARGB(255, 26, 26, 26),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageModel {
  final String messageid;
  final String sender;
  final String text;
  final String? fileUrl;
  final bool seen;
  final DateTime? createdon;

  MessageModel({
    required this.messageid,
    required this.sender,
    required this.text,
    this.fileUrl,
    required this.seen,
    this.createdon,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageid: map['messageid'],
      sender: map['sender'],
      text: map['text'],
      fileUrl: map['fileUrl'],
      seen: map['seen'],
      createdon: (map['createdon'] as Timestamp?)?.toDate(),
    );
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
