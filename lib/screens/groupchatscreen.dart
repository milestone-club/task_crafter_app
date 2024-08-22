import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class GroupChatScreen extends StatefulWidget {
  final String groupChatId;

  const GroupChatScreen({required this.groupChatId});

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController messageController = TextEditingController();
  late CollectionReference groupChatRef;
  List<dynamic> groupMembers = [];
  String groupName = '';

  @override
  void initState() {
    super.initState();
    groupChatRef = FirebaseFirestore.instance
        .collection('groupChats')
        .doc(widget.groupChatId)
        .collection('messages');
    fetchGroupName();
    fetchGroupMembers();
  }

  Future<void> fetchGroupName() async {
    DocumentSnapshot groupDoc = await FirebaseFirestore.instance
        .collection('groupChats')
        .doc(widget.groupChatId)
        .get();
    if (groupDoc.exists) {
      setState(() {
        groupName = groupDoc['groupName'] ?? 'Group Chat';
      });
    }
  }

  Future<void> fetchGroupMembers() async {
    DocumentSnapshot groupDoc = await FirebaseFirestore.instance
        .collection('groupChats')
        .doc(widget.groupChatId)
        .get();
    if (groupDoc.exists) {
      setState(() {
        groupMembers = List<String>.from(
            groupDoc['members'] ?? []); // Ensure members is a list of user IDs
      });
    }
  }

  void sendMessage(String message, {String? fileUrl}) async {
    if (message.isNotEmpty) {
      await groupChatRef.add({
        'text': message,
        'fileUrl': fileUrl,
        'senderId': FirebaseAuth.instance.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [], // Initialize as an empty list
      });
      messageController.clear();
    }
  }

  Future<Map<String, dynamic>> fetchSenderDetails(String senderId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }
    return {};
  }

  void markMessageAsRead(String messageId) async {
    await groupChatRef.doc(messageId).update({
      'readBy': FieldValue.arrayUnion([FirebaseAuth.instance.currentUser!.uid]),
    });
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
          .child('group_chat_files/$currentUserId/${file.name}');
      UploadTask uploadTask = storageReference.putFile(File(file.path!));
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
      String fileUrl = await taskSnapshot.ref.getDownloadURL();
      sendMessage(file.name, fileUrl: fileUrl);
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  Future<void> openFile(String fileUrl, String? fileName) async {
    final file = await _downloadFile(fileUrl, fileName!);
    if (file == null) return;
    print('Path: ${file.path}');
    OpenFile.open(file.path);
  }

  Future<File?> _downloadFile(String fileUrl, String fileName) async {
    final appStorage = await getExternalStorageDirectory();
    final file = File('${appStorage!.path}/$fileName');

    try {
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
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            groupName,
            style: const TextStyle(
              color: Color.fromARGB(255, 7, 7, 7),
            ),
          ),
          backgroundColor: const Color(0xFFF1F4F8),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/chat-background.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: groupChatRef
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<DocumentSnapshot> messages = snapshot.data!.docs;

                    DateTime? currentDate;
                    bool isFirstMessage = true;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        var messageData =
                            messages[index].data() as Map<String, dynamic>;
                        String messageId = messages[index].id;
                        bool isMe = messageData['senderId'] ==
                            FirebaseAuth.instance.currentUser!.uid;
                        DateTime messageTime =
                            (messageData['createdAt'] as Timestamp?)
                                    ?.toDate() ??
                                DateTime.now();

                        final String time =
                            '${messageTime.hour}:${messageTime.minute.toString().padLeft(2, '0')}';

                        // Mark message as read
                        markMessageAsRead(messageId);

                        if (currentDate == null ||
                            currentDate?.day != messageTime.day) {
                          currentDate = messageTime;
                          if (!isFirstMessage) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 10),
                                Text(
                                  '${messageTime.day}/${messageTime.month}/${messageTime.year}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                                const SizedBox(height: 5),
                                FutureBuilder<Map<String, dynamic>>(
                                  future: fetchSenderDetails(
                                      messageData['senderId']),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    var senderDetails = snapshot.data!;
                                    return _buildMessageBubble(
                                        messageData, isMe, time, senderDetails);
                                  },
                                ),
                              ],
                            );
                          } else {
                            isFirstMessage = false;
                          }
                        }

                        return FutureBuilder<Map<String, dynamic>>(
                          future: fetchSenderDetails(messageData['senderId']),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            var senderDetails = snapshot.data!;
                            return _buildMessageBubble(
                                messageData, isMe, time, senderDetails);
                          },
                        );
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
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () {
                          sendMessage(messageController.text.trim());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isMe,
      String time, Map<String, dynamic> senderDetails) {
    String senderName =
        '${senderDetails['fName']} ${senderDetails['lastName']}';

    List<dynamic> readByList = messageData['readBy'] is List
        ? List<dynamic>.from(messageData['readBy'])
        : [];
    bool isReadByMe =
        readByList.contains(FirebaseAuth.instance.currentUser!.uid);
    bool isReadByAll = readByList.length == groupMembers.length;

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
            if (messageData['text'] != null)
              Text(
                messageData['text'],
                style: const TextStyle(fontSize: 16),
              ),
            if (messageData['fileUrl'] != null)
              GestureDetector(
                onTap: () =>
                    openFile(messageData['fileUrl'], messageData['text']),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    messageData['text'] ?? 'File Attachment',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 5),
            Text(
              time,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isReadByAll)
                  const Icon(Icons.done_all, size: 14, color: Colors.blue)
                else if (isReadByMe && isMe)
                  const Icon(Icons.done_all, size: 14, color: Colors.blue)
                else if (!isReadByMe && isMe)
                  const Icon(Icons.done, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  senderName,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
