import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatscreen.dart';
import 'creategroupchatscreen.dart';
import 'groupchatscreen.dart';
import 'package:async/async.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({Key? key}) : super(key: key);

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController searchController = TextEditingController();
  List<DocumentSnapshot> searchResults = [];

  @override
  Widget build(BuildContext context) {
    var he = MediaQuery.of(context).size.height;
    var wi = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Text(
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 30,
              color: Color.fromARGB(255, 11, 14, 20),
              backgroundColor: Color.fromARGB(255, 255, 255, 255),
            ),
            'All Chats'),
        actions: [
          IconButton(
            icon: Icon(Icons.group_add),
            onPressed: createGroupChat,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: wi * 0.05, vertical: he * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by first name, last name, or email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: searchUsers,
                    ),
                  ),
                ),
                SizedBox(height: he * 0.02),
                SizedBox(height: 10),
                buildChats(),
                SizedBox(height: 10),
                searchResults.isEmpty
                    ? Center(
                        child: Text(
                          '',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : Column(
                        children: searchResults.map((userDoc) {
                          String firstName = userDoc['firstName'];
                          String lastName = userDoc['lastName'];
                          String email = userDoc['email'];

                          // Fetch fcmToken from users collection
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userDoc
                                    .id) // Assuming userDoc.id is the document ID of the user
                                .get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              }
                              if (!userSnapshot.hasData ||
                                  userSnapshot.hasError) {
                                return Text('Error fetching user data');
                              }

                              var userDoc = userSnapshot.data!;
                              String deviceToken = userDoc['fcmToken'] ??
                                  ''; // Safe access to fcmToken

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    firstName[0].toUpperCase(),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text('$firstName $lastName'),
                                subtitle: Text(email),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        recipientId: userDoc.id,
                                        recipientName: '$firstName $lastName',
                                        deviceToken: deviceToken,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> searchUsers() async {
    String searchText = searchController.text.trim().toLowerCase();

    if (searchText.isNotEmpty) {
      try {
        QuerySnapshot firstNameQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('fName', isGreaterThanOrEqualTo: searchText)
            .where('fName', isLessThanOrEqualTo: searchText + '\uf8ff')
            .get();

        QuerySnapshot lastNameQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('lastName', isGreaterThanOrEqualTo: searchText)
            .where('lastName', isLessThanOrEqualTo: searchText + '\uf8ff')
            .get();

        QuerySnapshot emailQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: searchText)
            .get();

        setState(() {
          searchResults = [
            ...firstNameQuery.docs,
            ...lastNameQuery.docs,
            ...emailQuery.docs
          ];
        });
      } catch (e) {
        print('Error searching users: $e');
      }
    } else {
      setState(() {
        searchResults = [];
      });
    }
  }

  void createGroupChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroupChatScreen(),
      ),
    );
  }

  Widget buildChats() {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: StreamZip([
        FirebaseFirestore.instance
            .collection('chatrooms')
            .where('participants',
                arrayContains: FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        FirebaseFirestore.instance
            .collection('groupChats')
            .where('members',
                arrayContains: FirebaseAuth.instance.currentUser!.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        List<DocumentSnapshot> allChats = [];
        if (snapshot.hasData) {
          for (var querySnapshot in snapshot.data!) {
            allChats.addAll(querySnapshot.docs);
          }

          // Sort allChats based on the last message time or created time
          allChats.sort((a, b) {
            Timestamp aTime = (a.data() as Map<String, dynamic>)
                    .containsKey('lastMessageTime')
                ? a['lastMessageTime']
                : (a.data() as Map<String, dynamic>).containsKey('createdAt')
                    ? a['createdAt']
                    : Timestamp.now();
            Timestamp bTime = (b.data() as Map<String, dynamic>)
                    .containsKey('lastMessageTime')
                ? b['lastMessageTime']
                : (b.data() as Map<String, dynamic>).containsKey('createdAt')
                    ? b['createdAt']
                    : Timestamp.now();
            return bTime.compareTo(aTime);
          });
        }

        if (allChats.isEmpty) {
          return Center(
            child: Text(
              'No chats found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return Column(
          children: allChats.map((chatDoc) {
            if (chatDoc.reference.path.startsWith('chatrooms')) {
              List<dynamic> participants = chatDoc['participants'];
              String recipientId = participants.firstWhere(
                (id) => id != FirebaseAuth.instance.currentUser!.uid,
                orElse: () => '',
              );

              if (recipientId.isEmpty) {
                return ListTile(
                  title: Text('Error: No recipient found'),
                );
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('profiles')
                    .doc(recipientId)
                    .get(),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (!profileSnapshot.hasData || profileSnapshot.hasError) {
                    return Text('Error fetching user data');
                  }
                  var profileDoc = profileSnapshot.data!;
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(recipientId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (!userSnapshot.hasData || userSnapshot.hasError) {
                        return Text('Error fetching user data');
                      }
                      var userDoc = userSnapshot.data!;
                      String firstName = profileDoc['firstName'];
                      String lastName = profileDoc['lastName'];
                      String deviceToken =
                          userDoc['fcmToken'] ?? ''; // Safe access to fcmToken
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            firstName[0].toUpperCase(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text('$firstName $lastName'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                recipientId: recipientId,
                                recipientName: '$firstName $lastName',
                                deviceToken: deviceToken,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            } else {
              String groupName = chatDoc['groupName'];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Text(
                    groupName[0].toUpperCase(),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(groupName),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GroupChatScreen(groupChatId: chatDoc.id),
                    ),
                  );
                },
              );
            }
          }).toList(),
        );
      },
    );
  }
}
