import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsPage extends StatefulWidget {
  final String projectId;

  const CommentsPage({Key? key, required this.projectId}) : super(key: key);

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _commentController = TextEditingController();

  Future<String> _getCurrentUserFirstName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          return userDoc.get('firstName');
        } else {
          throw StateError('Document does not exist');
        }
      } else {
        throw StateError('No user is currently signed in');
      }
    } catch (e) {
      print('Error fetching current user first name: $e');
      return 'Author';
    }
  }

  void _addComment() async {
    String comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    String authorName = await _getCurrentUserFirstName();

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('comments')
        .add({
      'comment': comment,
      'author': authorName,
      'timestamp': FieldValue.serverTimestamp(),
      'pinned': false, // Initialize as not pinned
    });

    _commentController.clear();
  }

  void _addReply(String commentId, String reply) async {
    if (reply.isEmpty) return;

    String replyAuthorName = await _getCurrentUserFirstName();

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .add({
      'reply': reply,
      'author': replyAuthorName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _togglePin(String commentId, bool currentPinStatus) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('comments')
        .doc(commentId)
        .update({'pinned': !currentPinStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addComment,
              child: Text('Add Comment'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('projects')
                    .doc(widget.projectId)
                    .collection('comments')
                    .orderBy('pinned',
                        descending: true) // Pinned comments first
                    .orderBy('timestamp', descending: true) // Then by timestamp
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No comments found'));
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((commentDoc) {
                      String commentId = commentDoc.id;
                      String commentText = commentDoc['comment'];
                      String commentAuthor = commentDoc['author'];
                      bool isPinned = commentDoc['pinned'] ?? false;

                      return GestureDetector(
                        onTap: () {
                          // Handle tap to collapse replies (if any)
                          FocusScope.of(context).unfocus();
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    commentAuthor, // Display first name
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isPinned
                                          ? Icons.push_pin
                                          : Icons.pin_outlined,
                                      color:
                                          isPinned ? Colors.blue : Colors.grey,
                                    ),
                                    onPressed: () {
                                      _togglePin(commentId, isPinned);
                                    },
                                  ),
                                ],
                              ),
                              Text(commentText),
                              // Add reply functionality here
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
