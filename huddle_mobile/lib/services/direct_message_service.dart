import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

class DirectMessageService {
    final _api = ApiClient();

    //sohbet sekmesindeki dm listesi
    Future<List<Map<String, dynamic>>> getConversations() async {
        final response = await _api.dio.get('/direct-messages/conversations');
        return List<Map<String, dynamic>>.from(response.data);
    }

    //belirli bir kullanıcıyla mesaj geçmişi
    Future<List<Map<String, dynamic>>> getMessages(String otherUserId) async {
        final response = await _api.dio.get('/direct-messages/$otherUserId');
        return List<Map<String, dynamic>>.from(response.data);
    }

    //o kullanıcıya mesaj gönderir
    Future<Map<String, dynamic>> sendMessage(String otherUserId, String content) async {
        try {
            final response = await _api.dio.post(
                '/direct-messages/$otherUserId',
                data: {'content': content},
            );
            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Mesaj gönderilemedi.';
            return {'success': false, 'message': message};
        }
    }

    //mesajı siler
    Future<Map<String, dynamic>> deleteMessage(String otherUserId, String messageId) async {
        try {
            await _api.dio.delete('/direct-messages/$otherUserId/$messageId');
            return {'success': true};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Mesaj silinemedi.';
            return {'success': false, 'message': message};
        }
    }

    //iki kullanıcı arasında paylaşılan fotoğrafları getirir
    Future<List<Map<String, dynamic>>> getPhotos(String otherUserId) async {
        final response = await _api.dio.get('/direct-messages/$otherUserId/photos');
        return List<Map<String, dynamic>>.from(response.data);
    }

    //dm sohbetine foto yükler
    Future<Map<String, dynamic>> uploadPhoto(String otherUserId, File imageFile) async {
        try {
            final fileName = imageFile.path.split('/').last;
            final formData = FormData.fromMap({
                'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
            });

            final response = await _api.dio.post('/upload/direct-messages/$otherUserId/photo', data: formData);
            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Fotoğraf yüklenemedi.';
            return {'success': false, 'message': message};
        }
    }

    //"yazıyorum" bildirimi gönderir (hata olursa sessizce yutulur, kritik bir işlem değil)
    Future<void> notifyTyping(String otherUserId) async {
        try {
            await _api.dio.post('/direct-messages/$otherUserId/typing');
        } catch (e) {
            // sessiz başarısızlık
        }
    }

    //karşı tarafın şu an yazıp yazmadığını sorar
    Future<bool> getTypingStatus(String otherUserId) async {
        try {
            final response = await _api.dio.get('/direct-messages/$otherUserId/typing');
            return response.data['isTyping'] == true;
        } catch (e) {
            return false;
        }
    }
}
