import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> getOAuth2AccessToken() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Retrieve the user's ID token from Firebase Authentication
      String? idToken = await user.getIdToken();

      // Exchange the ID token for an OAuth2 access token from your backend
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Parse the OAuth2 access token from the response
        Map<String, dynamic> responseBody = json.decode(response.body);
        return responseBody['access_token'];
      } else {
        print('Failed to get OAuth2 access token: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } else {
      print('No user is currently signed in.');
      return null;
    }
  }
}
