import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';


class EventService {
    final _api = ApiClient();

    // kategori listesini getirir
    Future<List<Map<String, dynamic>>> getCategories() async {
        final response = await _api.dio.get('/categories');
        return List<Map<String, dynamic>>.from(response.data);
    }

    // yeni etkinlik oluşturur
    Future<Map<String, dynamic>> createEvent({
        required String categoryId,
        required String title,
        required String description,
        required String address,
        required double latitude,
        required double longitude,
        required int targetGender,
        required DateTime startTime,
    }) async {
        try {
            final response = await _api.dio.post('/events', data: {
                'categoryId': categoryId,
                'title': title,
                'description': description,
                'address': address,
                'latitude': latitude,
                'longitude': longitude,
                'targetGender': targetGender,
                'startTime': startTime.toUtc().toIso8601String(),
            });

            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Etkinlik oluşturulamadı.';
            return {'success': false, 'message': message};
        }
    }

    // var olan bir etkinliği günceller 
    Future<Map<String, dynamic>> updateEvent({
        required String eventId,
        required String categoryId,
        required String title,
        required String description,
        required String address,
        required double latitude,
        required double longitude,
        required int targetGender,
        required DateTime startTime,
    }) async {
        try {
            final response = await _api.dio.put('/events/$eventId', data: {
                'categoryId': categoryId,
                'title': title,
                'description': description,
                'address': address,
                'latitude': latitude,
                'longitude': longitude,
                'targetGender': targetGender,
                'startTime': startTime.toUtc().toIso8601String(),
            });

            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final data = e.response?.data;
            final message = (data is Map && data['message'] != null)
                ? data['message']
                : 'Etkinlik güncellenemedi.';
            return {'success': false, 'message': message};
        }
    }

    // etkinliğe görsel yükler (UploadController'daki endpoint'e)
    Future<bool> uploadEventImage(String eventId, File imageFile) async {
        try {
            final fileName = imageFile.path.split('/').last;
            final formData = FormData.fromMap({
                'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
            });

            final response = await _api.dio.post('/upload/event/$eventId', data: formData);
            return response.statusCode == 200;
        } on DioException {
            return false;
        }
    }

    // etkinlik listesini getirme
    Future<List<Map<String, dynamic>>> getEvents() async {
        final response = await _api.dio.get('/events');
        return List<Map<String, dynamic>>.from(response.data);
    }

    //tek bir etkinliğin detayını getirir
    Future<Map<String, dynamic>> getEventById(String id) async {
        final response = await _api.dio.get('/events/$id');
        return Map<String, dynamic>.from(response.data);
    }

    //etkinliğe katılım isteği gönderme
    Future<Map<String, dynamic>> joinEvent(String eventId) async {
        try {
            await _api.dio.post('/events/$eventId/join');
            return {'success': true};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'İstek gönderilemedi.';
            return {'success': false, 'message': message};
        }
    }


    // katılım isteğini/kaydını iptal eder
    Future<Map<String, dynamic>> cancelJoinRequest(String eventId) async {
        try {
            await _api.dio.delete('/events/$eventId/join');
            return {'success': true};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'İptal edilemedi.';
            return {'success': false, 'message': message};
        }
    }

    // kullanıcının oluşturduğu etkinlikleri getirir (Etkinliklerim)
    Future<List<Map<String, dynamic>>> getMyEvents() async {
        final response = await _api.dio.get('/events/my');
        return List<Map<String, dynamic>>.from(response.data);
    }

    //katıldığım etkinlikler
    Future<List<Map<String, dynamic>>> getJoinedEvents() async {
        final response = await _api.dio.get('/events/joined');
        return List<Map<String, dynamic>>.from(response.data);
    }

    // kullanıcının sahip olduğu tüm etkinlikler için bekleyen katılım isteklerini getirir (bildirimler)
    Future<List<Map<String, dynamic>>> getMyPendingRequests() async {
        final response = await _api.dio.get('/events/requests');
        return List<Map<String, dynamic>>.from(response.data);
    }

    // bir katılım isteğini onaylar ya da reddeder
    Future<Map<String, dynamic>> respondToRequest(String participantId, bool approve) async {
        try {
            await _api.dio.put(
                '/events/requests/$participantId/respond',
                queryParameters: {'approve': approve},
            );
            return {'success': true};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'İşlem gerçekleştirilemedi.';
            return {'success': false, 'message': message};
        }
    }

        // etkinliğe anı fotoğrafı yükler
    Future<Map<String, dynamic>> uploadEventMemoryPhoto(String eventId, File imageFile) async {
        try {
            final fileName = imageFile.path.split('/').last;
            final formData = FormData.fromMap({
                'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
            });

            final response = await _api.dio.post('/upload/event/$eventId/photo', data: formData);
            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Fotoğraf yüklenemedi.';
            return {'success': false, 'message': message};
        }
    }

    // bir etkinliğe eklenmiş anı fotoğraflarını getirir
    Future<List<Map<String, dynamic>>> getEventPhotos(String eventId) async {
        final response = await _api.dio.get('/events/$eventId/photos');
        return List<Map<String, dynamic>>.from(response.data);
    }

    // etkinlik kurucusunu değerlendirir (ekler ya da günceller)
    Future<Map<String, dynamic>> rateEvent(
        String eventId, 
        int score, 
        int communicationScore,
        int organizationScore,
        int warmthScore,
        String? comment
        ) async {
        try {
            await _api.dio.post('/events/$eventId/rating', data: {
                'score': score,
                'communicationScore': communicationScore,
                'organizationScore': organizationScore,
                'warmthScore': warmthScore,
                'comment': comment,
            });
            return {'success': true};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Değerlendirme kaydedilemedi.';
            return {'success': false, 'message': message};
        }
    }
}