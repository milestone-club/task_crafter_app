// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateGroupChatScreen extends StatefulWidget {
  @override
  _CreateGroupChatScreenState createState() => _CreateGroupChatScreenState();
}

class _CreateGroupChatScreenState extends State<CreateGroupChatScreen> {
  final TextEditingController groupNameController = TextEditingController();
  List<DocumentSnapshot> allUsers = [];
  List<String> selectedMembers = [];

  @override
  void initState() {
    super.initState();
    fetchAllUsers();
  }

  Future<void> fetchAllUsers() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('profiles').get();
      setState(() {
        allUsers = querySnapshot.docs;
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: createGroupChat,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: groupNameController,
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: allUsers.isEmpty
                  ? const Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: allUsers.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot userDoc = allUsers[index];
                        String userId = userDoc.id;
                        String firstName = userDoc['firstName'];
                        String lastName = userDoc['lastName'];
                        String email = userDoc['email'];

                        return CheckboxListTile(
                          title: Text('$firstName $lastName'),
                          subtitle: Text(email),
                          value: selectedMembers.contains(userId),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedMembers.add(userId);
                              } else {
                                selectedMembers.remove(userId);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> createGroupChat() async {
    String groupName = groupNameController.text.trim();
    if (groupName.isNotEmpty && selectedMembers.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('groupChats').add({
          'groupName': groupName,
          'members': selectedMembers,
          'createdAt': Timestamp.now(),
        });
        Navigator.pop(context);
      } catch (e) {
        print('Error creating group chat: $e');
      }
    } else {
      print('Group name or members cannot be empty');
    }
  }
}
