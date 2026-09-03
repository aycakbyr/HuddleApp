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
    Future<Map<String, dynamic>> sendMessage(String communityId, String content) async {
        try{
            final response = await _api.dio.post(
                '/communities/$communityId/messages',
                data: {'content': content},
            );
            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Mesaj gönderilemedi.';
            return {'success': false, 'message': message};
        }
    }
}