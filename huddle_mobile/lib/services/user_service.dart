import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

class UserService {
    final _api = ApiClient();

    //herkese açık profili getirr
    Future<Map<String, dynamic>> getProfile(String userId) async {
        final response = await _api.dio.get('/users/$userId');
        return Map<String, dynamic>.from(response.data);
    }

    //kullanıcıyı takip etme
    Future<Map<String, dynamic>> follow(String userId) async {
        try{
            await _api.dio.post('/users/$userId/follow');
            return {'success': true};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Takip edilemedi.';
            return {'success': false, 'message': message};
        }
    }

    //takibi bırakır
    Future<Map<String, dynamic>> unfollow(String userId) async {
        try{
            await _api.dio.delete('/users/$userId/follow');
            return {'success': true};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Takipten çıkılamadı.';
            return {'success': false, 'message': message};
        }
    }

    //takipçi listesini getirir
    Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
        final response = await _api.dio.get('/users/$userId/followers');
        return List<Map<String, dynamic>>.from(response.data);
    }

    //takip edilenler listeesini getirir
    Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
        final response = await _api.dio.get('/users/$userId/following');
        return List<Map<String, dynamic>>.from(response.data);
    }

    //kullanıcının eklediği foto getirir
    Future<List<Map<String, dynamic>>> getUserPhotos(String userId) async {
        final response = await _api.dio.get('/users/$userId/photos');
        return List<Map<String, dynamic>>.from(response.data);
    }

    //kullanıcının oluşturduğu etkinlikleri getirir (herkese açık profilde)
    Future<List<Map<String, dynamic>>> getUserEvents(String userId) async {
        final response = await _api.dio.get('/users/$userId/events');
        return List<Map<String, dynamic>>.from(response.data);
    }

    //alınan değerlendirmeler
    Future<Map<String, dynamic>> getUserRatings(String userId) async {
        final response = await _api.dio.get('/users/$userId/ratings');
        return Map<String, dynamic>.from(response.data);
    }

    //profile doğrudan (bir etkinliğe bağlı olmadan) fotoğraf ekler
    Future<Map<String, dynamic>> uploadProfilePhoto(File imageFile) async {
        try {
            final fileName = imageFile.path.split('/').last;
            final formData = FormData.fromMap({
                'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
            });

            final response = await _api.dio.post('/upload/profile/photo', data: formData);
            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Fotoğraf yüklenemedi.';
            return {'success': false, 'message': message};
        }
    }

    // pp ekle değiştir
    Future<Map<String, dynamic>> updateProfilePicture(File imageFile) async {
        try{
            final fileName = imageFile.path.split('/').last;
            final formData = FormData.fromMap({
                'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
            });

            final response = await _api.dio.post('/upload/profile/picture', data: formData);
            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Fotoğraf yüklenemedi.';
            return {'success': false, 'message': message};
        }
    }
}