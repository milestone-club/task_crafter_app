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

    setState(() {}); // Refresh the page to show the new reply
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

                      return CommentWidget(
                        projectId: widget.projectId,
                        commentId: commentId,
                        commentText: commentText,
                        commentAuthor: commentAuthor,
                        isPinned: isPinned,
                        addReply: _addReply,
                        togglePin: _togglePin,
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

class CommentWidget extends StatefulWidget {
  final String projectId;
  final String commentId;
  final String commentText;
  final String commentAuthor;
  final bool isPinned;
  final void Function(String commentId, String reply) addReply;
  final void Function(String commentId, bool currentPinStatus) togglePin;

  const CommentWidget({
    Key? key,
    required this.projectId,
    required this.commentId,
    required this.commentText,
    required this.commentAuthor,
    required this.isPinned,
    required this.addReply,
    required this.togglePin,
  }) : super(key: key);

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  bool showReplies = false;
  final TextEditingController _replyController = TextEditingController();

  void _toggleReplies() {
    setState(() {
      showReplies = !showReplies;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (showReplies) {
          setState(() {
            showReplies = false;
          });
        }
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.commentAuthor, // Display first name
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(
                    widget.isPinned ? Icons.push_pin : Icons.pin_outlined,
                    color: widget.isPinned ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () {
                    widget.togglePin(widget.commentId, widget.isPinned);
                  },
                ),
              ],
            ),
            Text(widget.commentText),
            TextButton(
              onPressed: _toggleReplies,
              child: Text(showReplies ? 'Hide Replies' : 'Show Replies'),
            ),
            if (showReplies) ...[
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('projects')
                    .doc(widget.projectId)
                    .collection('comments')
                    .doc(widget.commentId)
                    .collection('replies')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No replies found'));
                  }

                  return Column(
                    children: snapshot.data!.docs.map((replyDoc) {
                      String replyText = replyDoc['reply'];
                      String replyAuthor = replyDoc['author'];

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              replyAuthor, // Display first name
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(replyText),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              SizedBox(height: 10),
              TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  labelText: 'Reply',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 5),
              ElevatedButton(
                onPressed: () {
                  widget.addReply(
                      widget.commentId, _replyController.text.trim());
                  _replyController.clear();
                  setState(() {
                    showReplies = false;
                  });
                },
                child: Text('Add Reply'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
