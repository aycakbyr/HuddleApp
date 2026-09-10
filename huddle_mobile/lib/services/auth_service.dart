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

    //şifre değiştirme
    Future<Map<String, dynamic>> changePassword({
        required String currentPassword,
        required String newPassword,
    }) async {
        try {
            final response = await _api.dio.put('/auth/change-password', data: {
                'currentPassword': currentPassword,
                'newPassword': newPassword,
            });
            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Şifre değiştirilemedi.';
            return {'success': false, 'message': message};
        }
    }

    //hesabı silme
    Future<Map<String, dynamic>> deleteAccount(String password) async {
        try {
            final response = await _api.dio.delete('/auth', data: {
                'password': password,
            });
            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Hesap silinemedi.';
            return {'success': false, 'message': message};
        }
    }

    //şifremi unuttum - maile kod gönderir
    Future<Map<String, dynamic>> forgotPassword(String email) async {
        try {
            final response = await _api.dio.post('/auth/forgot-password', data: {
                'email': email,
            });
            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Bir hata oluştu, lütfen tekrar dene.';
            return {'success': false, 'message': message};
        }
    }

    //kodu doğrulayıp şifreyi sıfırlar
    Future<Map<String, dynamic>> resetPassword({
        required String email,
        required String code,
        required String newPassword,
    }) async {
        try {
            final response = await _api.dio.post('/auth/reset-password', data: {
                'email': email,
                'code': code,
                'newPassword': newPassword,
            });
            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Şifre sıfırlanamadı.';
            return {'success': false, 'message': message};
        }
    }

    //google ile giriş - google'dan alınan idToken'ı backend'e doğrulatır
    Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
        try {
            final response = await _api.dio.post('/auth/google', data: {
                'idToken': idToken,
            });

            final token = response.data['token'];
            await _api.saveToken(token);

            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Google ile giriş yapılamadı.';
            return {'success': false, 'message': message};
        }
    }

    //google ile ilk kez girenler için doğum tarihi/cinsiyet tamamlama
    Future<Map<String, dynamic>> completeProfile({
        required int gender,
        required DateTime birthDate,
    }) async {
        try {
            final response = await _api.dio.put('/auth/complete-profile', data: {
                'gender': gender,
                'birthDate': birthDate.toUtc().toIso8601String(),
            });
            return {'success': true, 'data': response.data};
        } on DioException catch (e) {
            final message = e.response?.data?['message'] ?? 'Profil tamamlanamadı.';
            return {'success': false, 'message': message};
        }
    }

}