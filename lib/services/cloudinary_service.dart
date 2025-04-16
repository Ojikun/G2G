import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName = 'dtgvivwfa';
  final String uploadPreset = 'g2g_unsigned';

  Future<String?> uploadImage(File image) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request =
        http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = uploadPreset
          ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final res = await response.stream.bytesToString();
      final jsonResponse = json.decode(res);
      return jsonResponse['secure_url'];
    } else {
      print('Upload failed with status ${response.statusCode}');
      return null;
    }
  }
}
