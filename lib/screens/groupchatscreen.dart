// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        groupName = groupDoc['groupName'];
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
        groupMembers = groupDoc['members'];
      });
    }
  }

  void sendMessage(String message) async {
    if (message.isNotEmpty) {
      await groupChatRef.add({
        'text': message,
        'senderId': FirebaseAuth.instance.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [FirebaseAuth.instance.currentUser!.uid],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
      ),
      body: Column(
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
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var messageData =
                        messages[index].data() as Map<String, dynamic>;
                    bool isMe = messageData['senderId'] ==
                        FirebaseAuth.instance.currentUser!.uid;
                    DateTime messageTime =
                        (messageData['createdAt'] as Timestamp?)?.toDate() ??
                            DateTime.now();

                    final String time =
                        '${messageTime.hour}:${messageTime.minute.toString().padLeft(2, '0')}';

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
                              style:
                                  const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 5),
                            FutureBuilder<Map<String, dynamic>>(
                              future:
                                  fetchSenderDetails(messageData['senderId']),
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
                          return const Center(child: CircularProgressIndicator());
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
                      sendMessage(messageController.text.trim());
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

  Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isMe,
      String time, Map<String, dynamic> senderDetails) {
    String senderName =
        '${senderDetails['fName']} ${senderDetails['lastName']}';

    bool isReadByMe =
        messageData['readBy'].contains(FirebaseAuth.instance.currentUser!.uid);
    bool isReadByAll = messageData['readBy'].length == groupMembers.length;

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
            Text(
              messageData['text'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              time,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            if (!isMe) ...[
              const SizedBox(height: 5),
              Text(
                senderName,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
            Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (isReadByMe)
                  const Icon(
                    Icons.check,
                    size: 18,
                    color: Colors.grey,
                  ),
                if (isReadByAll)
                  const Icon(
                    Icons.check,
                    size: 18,
                    color: Colors.blue,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
