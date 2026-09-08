import 'package:dio/dio.dart';
import 'api_client.dart';

class MessageService {
    final _api = ApiClient();

    //bir topluluğun sohbet geçmişini getirir
    Future<List<Map<String, dynamic>>> getMessages(String communityId) async {
        final response = await _api.dio.get('/communities/$communityId/messages');
        return List<Map<String, dynamic>>.from(response.data);
    }

    //topluluğa yeni mesaj gönderir
    Future<Map<String, dynamic>> sendMessage(String communityId, String content, {bool isAnnouncement = false}) async {
        try{
            final response = await _api.dio.post(
                '/communities/$communityId/messages',
                data: {'content': content, 'isAnnouncement': isAnnouncement }, //isimli, isteğe bağlı parametreler
            );
            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Mesaj gönderilemedi.';
            return {'success': false, 'message': message};
        }
    }

    //mesajı siler
    Future<Map<String, dynamic>> deleteMessage(String communityId, String messageId) async {
        try {
            await _api.dio.delete('/communities/$communityId/messages/$messageId');
            return {'success': true};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Mesaj silinemedi.';
            return {'success': false, 'message': message};
        }
    }
}