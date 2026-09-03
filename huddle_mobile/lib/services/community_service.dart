import 'package:dio/dio.dart';
import 'api_client.dart';

class CommunityService {
    final _api = ApiClient();

    //yeni topluluk oluşturmak için
    Future<Map<String, dynamic>> createCommunity({
        required String name,
        required String description,
    }) async {
        try{
            final response = await _api.dio.post('/communities', data : {
                'name': name,
                'description': description,
            });
            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Topluluk oluşturulamadı. ';
            return {'success': false, 'message': message};
        }
    }

    // tüm topluluklarının listesini getirir
    Future<List<Map<String, dynamic>>> getCommunities() async {
        final response = await _api.dio.get('/communities');
        return List<Map<String, dynamic>>.from(response.data);
    }

    //tek bir topluluğun detayını getirir
    Future<Map<String, dynamic>> getCommunityById(String id) async {
        final response = await _api.dio.get('/communities/$id');
        return Map<String, dynamic>.from(response.data);
    }

    //topluluğa katılma isteği gönderir
    Future<Map<String, dynamic>> joinCommunity(String communityId) async{
        try{
            await _api.dio.post('/communities/$communityId/join');
            return {'success': true};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'İstek gönderilemedi.';
            return {'success': false, 'message': message};
        }
    }

    //gönderilen katılım isteğini iptal etme
    Future<Map<String, dynamic>> cancelJoinRequest(String communityId) async {
        try{
            await _api.dio.delete('/communities/$communityId/join');
            return {'success': true};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'İptal edilemedi.';
            return {'success': false, 'message': message};
        }
    }

    //topluluktan ayrılma
    Future<Map<String, dynamic>> leaveCommunity(String communityId) async {
        try{
            await _api.dio.delete('/communities/$communityId/leave');
            return {'success': true};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Topluluktan ayrılınamadı.';
            return {'success': false, 'message': message};
        }
    }

    // bekleyen katılım isteklerini getirir
    Future<List<Map<String, dynamic>>> getPendingJoinRequests(String communityId) async {
        final response = await _api.dio.get('/communities/$communityId/requests');
        return List<Map<String, dynamic>>.from(response.data);
    }

    //katılım isteğini onaylar ya da reddeder
    Future<Map<String, dynamic>> respondToJoinRequest(
        String communityId,
        String requestId,
        bool approve,
    ) async {
        try{
            await _api.dio.put(
                '/communities/$communityId/requests/$requestId/respond',
                queryParameters: {'approve': approve},
            );
            return {'success': true};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'İşlem gerçekleştirilemedi.';
            return {'success': false, 'message': message};
        }
    }

    //bir üyeyi topluluktan çıkarır
    Future<Map<String, dynamic>> removeMember(String communityId, String userId) async
    {
        try{
            await _api.dio.delete('/communities/$communityId/members/$userId');
            return {'success': true};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Üye çıkarılamadı.';
            return {'success': false, 'message': message};
        }
    }
}