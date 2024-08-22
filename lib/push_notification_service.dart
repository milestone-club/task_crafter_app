import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;

class PushNotificationService {
  static Future<String> getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "taskcrafter-a7c64",
      "private_key_id": "905d6c73021339efe7805d77b1730f3517c9a634",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC4Fs9dRZCSXaCj\nu/PxTJhaSo/1gqm2+sE641C8OAk2cT238WjK7m+BfXGkKG3iwLZ+VHI4zTzwRtxV\nkJDaaV2ebua2pSfb7H/44AAX/8yLbGvhDvpQF2gVZ44spv1WKUicAFsVBefnS7tK\nBxFJbEV+PPEpmoukd4/6KOqURQOwz/DXlh/7PRzDLqSk959SjW9u3GEVARuYerqS\nNk4c3T4b7LhYfppbNPf1vMK9Z9Nd8NhleALl3OQisS4Sj3KpYkEDZ3cG9zwf2Mur\n8aFngHcGY94Dlkx+oMBksATnKWZOMVL/MAoeSETFyAvwgbvLnYcYweCieqYruZ/b\nT1GSgx/ZAgMBAAECggEABH26+KKxNp7t47y6xHbqyx4hUbsqto36z5va3QKtd9xu\npemP9c54HjPAJWH+n072DNI02K2qKE8EQlqk7A0wxWQdgRR5qtgD3b+iRPOeywJ9\nxcd6pCBUD9yfR3fZ+6OFc9fe4P4MRLRwaOuP+Id5kQ090XblpAEuPCtKIMynvMUl\nOW0AIYB/JjxhLvMNI3s57IjskU182qhLARWjwlEUMDK+4fk3lguGysomwOcGwhGy\npVSm0J5HW95Qs8vLH4mQVUZgNQ9v4BQp70FxfJkM3mIBsi31xngBTn7pVc1chtnM\nBdw2kT0pakR4ZBx78op1aS9kY8Lu4tJZgZVrMIxY4QKBgQD9vwgI5p6pL84nUuC9\nGlC9GFFPspDvegeGVo91+4IaX1zDiuXbsuypUkUMLOKRJucDZhSqdi955a/iDIXQ\n05ZH5snYDrHddcZ2trR4KKIR1M7FMEdd4256db97mwI9J+0wMYiSiz7kRnESY34y\nPE8O81jUb+2T81HYkvD3DN9l4QKBgQC5uWRkS2CGEk0wWpkKhdVRsDXpYU774b5p\nOtkf6GHDcczi2v13TiQbl5F7/qc3gx5zvqKL7eQjGtArzZk+/iKdX4Jiej1BHvzQ\niamtu24uhqRlJji+YjtBY9jOgw9kMnFjUtR9hrYX/22a+KZDKpIaxwkWlIc+VKCl\nXpihf0oI+QKBgBYxcx50LURW7gz6brWba5xeWB5EW/DWF3pkb7+9868i0BY6O8hv\nacuVanyaIGbZpDLj5sLR+20J7cwzlDCjkO1Q/i5repsIBge0CyzHQQWWO0973YIU\ntkD3s3u4HwYCS/h/HJbUnveQQat+EDeMls2T8x0BfSIHkg0DLRguhAuBAoGAN/PC\navTKf5nD521j7eej/Jg5pbXLNdcspkc0Yoh/64G9WBrhga/o8OcYzWJKvk6iPfyQ\nu9dPg8PwM0IdiPzHMOI1RbXN/nB3edv/Yne1Gg82N8LsFW9CqtCJ4K1bVbRctK+f\nlLGg6lnpi2adsF6C5c5Qzpywofac7zUwhnbytwECgYEAkgKRbOVj1PPZHp7tScgw\nkYDXSjq1yyUmgO9yF0xyEexTw3++6haCX2+O7AtkK1BYEHB275hVeL6Ol5kxa/nS\n/btBGOleX+NZ/P6sH/8la+gApJBvNJnWMa1Ys73N6PchHnUQoxvKOKVrQtgyEpFe\nEGVfj7K3fHZrGl0VaSOFVBQ=\n-----END PRIVATE KEY-----\n",
      "client_email": "taskcrafter@taskcrafter-a7c64.iam.gserviceaccount.com",
      "client_id": "116282515029161466170",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/taskcrafter%40taskcrafter-a7c64.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes = [
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging'
    ];
    http.Client client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson), scopes);

    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
            scopes,
            client);
    client.close();
    return credentials.accessToken.data;
  }

  static Future<void> sendNotification(
      String deviceToken, String title, String body) async {
    final String serverKey = await getAccessToken();
    String endpointFirebaseCloudMessaging =
        'https://fcm.googleapis.com/v1/projects/taskcrafter-a7c64/messages:send';
    final Map<String, dynamic> message = {
      'message': {
        'token': deviceToken,
        'notification': {'title': title, 'body': body},
      }
    };
    final http.Response response = await http.post(
        Uri.parse(endpointFirebaseCloudMessaging),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverKey'
        },
        body: jsonEncode(message));
    if (response.statusCode == 200) {
      print('Notification sent successfully.');
    } else {
      print('Failed to send Notification: ${response.statusCode}');
    }
  }
}
