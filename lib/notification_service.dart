import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:task_crafter_app/auth_service.dart';

Future<void> sendNotification(String token, String title, String body) async {
  final String? serverToken = await AuthService().getOAuth2AccessToken();

  if (serverToken == null) {
    print('No OAuth2 access token available.');
    return;
  }

  final response = await http.post(
    Uri.parse(
        'https://fcm.googleapis.com/v1/projects/taskcrafter-a7c64/messages:send'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $serverToken',
    },
    body: jsonEncode({
      'message': {
        'token': token,
        'notification': {
          'title': title,
          'body': body,
        },
      }
    }),
  );

  if (response.statusCode == 200) {
    print('Notification sent successfully.');
  } else {
    print('Failed to send notification: ${response.statusCode}');
    print('Response: ${response.body}');
  }
}
