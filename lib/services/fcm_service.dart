import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';

class FCMServiceV1 {
  static const String fcmEndpoint =
      'https://fcm.googleapis.com/v1/projects/g2g-app-88cd1/messages:send'; // 🔥 Corrected

  static Future<void> sendPushNotification({
    required String targetToken,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final accountCredentials = ServiceAccountCredentials.fromJson({
      "type": "service_account",
      "project_id": "g2g-app-88cd1",
      "private_key_id": "e31584209d2202b22a8d053c75d22d24c3d9e022",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCPXkj3E3wTc+QZ\n+liW9QcXS8VYv+DUANJR3w2SMRtGs3/zyDNENxZZeNsKs6ggnk+C215hquUL6ZHr\nhxuhrM3AyS8Lcel3kDFSGrDRo+QQI1fenyZJxsv5tV1dGzAJ3tVj2boBde4cUQrx\ngLyUPA3zMOIirTOlA7sB0c8ODmsfzNGg9DbCiY7HN7QNxQRByjDMJXsjMhVIM5lk\nkM59/RRvmxKdwwYl8FuNEdwa1bM3qmcpHNo7ZDz0XwiJwpe1T1fBTFWQgqN6x9qN\nMNjeZTuaKsxJhGaFbJeW3+s0iAQH7TWLehMEa661arPSIsYpxtvGQukC7KVeMxDg\nR5EYcGtDAgMBAAECggEADO6/ydUh7SZ+hHIwlmipNUqQrvSbSFezbgIFjF/a127b\nwCOzR2UDIoEKnHvsuTyIOZ3ZdRmTkPztCWaZPhiDdIkkmEJNtPGQSv+JxO9x/c6v\nLEk48ypepG2q0i16RBNFnPAIA/4dkF2MwJCqi8ihc+pZJWQJ85aGXDl1e9qEthjp\nY9PidPga5Bz2KT0tvV/aR9rJwT6ICpZeAu8iwNOYOUOE5qWG7XYflpH/+/eFKBE9\nshXQVk1SZ9ud0tPTlUooa4jSdCddInpB8R6TBMyeCtckZw/yPwzPWmD8kxkg9qew\nXpEFI8kpTtTjHherex7NAU1r2muvW/F/Sv3P3TSzEQKBgQDG/od6X6jO58ih3Wrb\n59WRNGz52nt0ofCpwlOi0VJJlf9HWUnNOnXjC42ycvW4OADkYrR5q33DpW5CUZF5\nF6eGquDaOL8V3h7cnVt0/CfW6zSHFIShSyJxnomfc8Ex/tMdQpnVUiLJn8qmf2I8\ng9Vq4qdBGf4TAmcLLemjJEW0GwKBgQC4cFztMf+3pPatHEeHjR1D8yF/Ys3edsiP\nq16bBqmEYDb8UqZYbYHSS6FXp2ThoddsKk/rJ0S7TahkzXtd6VW1hoEMHX6KlDUp\n4/+CcsRgVVMye4ZjBCHXb5IgK0NxyCdK6ZMdBQHAlIVsOjv/D53lHEg61f5nfLaw\ng/VpEp6H+QKBgQDBVZ/Y1EHVLDqwkMf2eYr0dcP/CDdz/LYuqL/La6WQGuyXrHdY\nrpjEi4ASxUBYyAiN3BxOLcCVqg+y3T8CMGoyG6k0O3fjzheb7kJiKW6nj4NMTjIB\n51bCnu5E/hjQ8yy3u/Jr4E4uKFKiaxbNhqR+IVGwnYlNfMMSiHv7Zg1WywKBgDmn\n7nS7p4u6Bt7Qs0+dfmOKcpNGyMJdcY7v7FAcAgv+o9G26IdGHEooGFS1YGTkWdpX\nU8pX6TWALj7suT7/PSrU1Cx8X91kPUZOHsahp9/RbIOgd78mQIn/N7fUrm24OwhB\nAhsVQJn6E8dkYPL3580CTVYPJUsmglmltqbVCjfJAoGANq5j1IYAWK6HaDpungnr\nzoriQJcS7Kw2r0cC4axpZcEqFJ5cCGuwiRi1/IkZB1NNbLiP9y5J6Nv5kUIvLwXQ\ni34gZneyWOrMNLh31eFBxUZRSkpXLHCtE4dHKA0aCMhlAIJpKdMa9/CzXzORehoO\nVjm9G7w25BBaeCtLg8RJ2X0=\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-fbsvc@g2g-app-88cd1.iam.gserviceaccount.com",
      "client_id": "100609171754843333354",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40g2g-app-88cd1.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com",
    });

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(accountCredentials, scopes);

    final message = {
      "message": {
        "token": targetToken,
        "notification": {"title": title, "body": body},
        "android": {"priority": "high"},
      },
    };

    final response = await client.post(
      Uri.parse(fcmEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('✅ Push notification sent successfully!');
    } else {
      print('❌ Failed to send notification: ${response.body}');
    }

    client.close();
  }
}
