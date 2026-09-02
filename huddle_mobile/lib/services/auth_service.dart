import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthService {
    final _api = ApiClient();

    //kayıt olma
    Future<Map<String, dynamic>> register({
        required String email,
        required String password,
        required String displayName,
        required int gender,
        required DateTime birthDate,
    }) async {
        try {
            final response = await _api.dio.post('/auth/register', data: {
                'email': email,
                'password': password,
                'displayName': displayName,
                'gender': gender,
                'birthDate': birthDate.toUtc().toIso8601String(),
            });

            final token = response.data['token'];
            await _api.saveToken(token);

            return { 'success': true, 'data': response.data};
        } on DioException catch (e) {

            final message = e.response?.data?['message'] ?? 'Bir hata oluştu.';
            return {'success': false, 'message': message};
        }
    }

    //giriş yapma
    Future<Map<String, dynamic>> login ({
        required String email,
        required String password,
    }) async {
        try {
            final response = await _api.dio.post('/auth/login', data: {
                'email': email,
                'password': password,
            });

            final token = response.data['token'];
            await _api.saveToken(token); // token dönünce kaydediyoruz

            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Email veya şifre hatalı. ';
            return {'success': false, 'message': message};
        }
    }

    //çıkış yapma
    Future<void> logout() async {
        await _api.deleteToken();
    }

    //giriş yapmış kullanıcının profil bilgilerini getirir
    Future<Map<String, dynamic>?> getMe() async {
        try {
            final response = await _api.dio.get('/auth/me');
            return Map<String, dynamic>.from(response.data);
        } on DioException {
            return null;
        }
    }

    //kullanıcı adını günceller
    Future<Map<String, dynamic>> updateUsername(String username) async {
        try {
            final response = await _api.dio.put('/auth/username', data: {
                'username': username,
            });
            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Kullanıcı adı güncellenemedi.';
            return {'success': false, 'message': message};
        }
    }

}