import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final _storage = const FlutterSecureStorage(); // tokeni şifreli saklar

  ApiClient._internal() { //bu sınıftan sadece bir tane olsunu sağlar
    dio = Dio(BaseOptions(
      baseUrl: 'http://127.0.0.1:5191/api', //tüm isteklerin önüne eklenecek adres
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // Her isteğe otomatik token ekleme
    dio.interceptors.add(InterceptorsWrapper( //sürekli elle token eklemek zorunda bırakmıyor
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'token');
  }
}