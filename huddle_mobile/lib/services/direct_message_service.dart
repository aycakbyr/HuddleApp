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
}
