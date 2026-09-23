import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Configurable base URL:
  // - Android emulator: http://10.0.2.2:3000
  // - iOS simulator or desktop / web: http://localhost:3000
  String _baseUrl = 'http://localhost:3000';
  String? _authToken;

  String get baseUrl => _baseUrl;
  void setBaseUrl(String url) => _baseUrl = url;
  void setAuthToken(String? token) => _authToken = token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  /// Check server health & architecture
  Future<Map<String, dynamic>?> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/health'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] Health check error: $e');
    }
    return null;
  }

  /// 1. Upload Raw Image Directly:
  /// Backend takes care of 100% of the optimization (EXIF removal, WebP compression, BlurHash, 3 variants)
  Future<Map<String, dynamic>?> uploadRawImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/media/upload'),
      );

      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>;
      } else {
        debugPrint('[ApiService] Upload failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] Upload error: $e');
    }
    return null;
  }

  /// 2. User Authentication
  Future<bool> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _authToken = data['data']['token'];
        return true;
      }
    } catch (e) {
      debugPrint('[ApiService] Login error: $e');
    }
    return false;
  }

  /// 3. Fetch Locket Feed with Media URLs & BlurHash
  Future<List<dynamic>> fetchFeed({int limit = 50, int offset = 0}) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$_baseUrl/api/transactions/feed?limit=$limit&offset=$offset',
        ),
        headers: _headers,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] as List<dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] Fetch feed error: $e');
    }
    return [];
  }

  /// 4. Create Transaction linked to optimized Media Asset
  Future<Map<String, dynamic>?> createTransaction({
    required String type,
    required double amount,
    required String categoryId,
    String caption = '',
    String? mediaId,
    bool isPrivate = false,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/transactions'),
        headers: _headers,
        body: jsonEncode({
          'type': type,
          'amount': amount,
          'categoryId': categoryId,
          'caption': caption,
          'mediaId': mediaId,
          'isPrivate': isPrivate,
        }),
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] Create transaction error: $e');
    }
    return null;
  }

  /// 5. Toggle Emoji Reaction
  Future<Map<String, int>?> toggleReaction(
    String transactionId,
    String emoji,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/transactions/$transactionId/react'),
        headers: _headers,
        body: jsonEncode({'emoji': emoji}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rawMap = data['data']['reactions'] as Map<String, dynamic>;
        return rawMap.map((k, v) => MapEntry(k, v as int));
      }
    } catch (e) {
      debugPrint('[ApiService] Toggle reaction error: $e');
    }
    return null;
  }

  /// 6. Fetch 2-DB Storage Savings & Metrics
  Future<Map<String, dynamic>?> fetchStorageSavings() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/media/stats'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] Fetch storage savings error: $e');
    }
    return null;
  }
}
