import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../navigation/navigation_service.dart';
import '../storage/auth_storage.dart';

class ApiResponse {
  final bool success;
  final int statusCode;
  final dynamic data;
  final String? errorMessage;

  ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.errorMessage,
  });
}

class ApiService {
  static bool _isRefreshing = false;

  static Future<String?> _resolveToken({bool retry = true}) async {
    String? token = await AuthStorage.getAccessToken();
    if ((token == null || token.isEmpty) && retry) {
      final refreshed = await tryRefreshToken();
      if (refreshed) {
        token = await AuthStorage.getAccessToken();
      }
    }
    return token;
  }

  static Future<Map<String, String>> _getHeaders({bool withAuth = true, String? explicitToken}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = explicitToken ?? await AuthStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<bool> tryRefreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final refresh = await AuthStorage.getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        await AuthStorage.clearAuth();
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.refreshToken),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refresh}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map && body.containsKey('access')) {
          final newAccess = body['access'] as String;
          await AuthStorage.updateAccessToken(newAccess);
          if (body.containsKey('refresh')) {
            await AuthStorage.updateRefreshToken(body['refresh'] as String);
          }
          debugPrint('Token refreshed successfully.');
          return true;
        }
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
    } finally {
      _isRefreshing = false;
    }

    await AuthStorage.clearAuth();
    return false;
  }

  static Future<ApiResponse> get(String url, {bool withAuth = true, bool retry = true}) async {
    try {
      String? token;
      if (withAuth) {
        token = await _resolveToken(retry: retry);
        if (token == null || token.isEmpty) {
          NavigationService.navigateToLogin(message: 'Session expired. Please sign in again.');
          return ApiResponse(success: false, statusCode: 401, errorMessage: 'Session expired. Please sign in again.');
        }
      }

      final headers = await _getHeaders(withAuth: withAuth, explicitToken: token);
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 401 && withAuth && retry) {
        final refreshed = await tryRefreshToken();
        if (refreshed) {
          return await get(url, withAuth: withAuth, retry: false);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, statusCode: 0, errorMessage: 'Network error: $e');
    }
  }

  static Future<ApiResponse> post(String url, Map<String, dynamic> body, {bool withAuth = true, bool retry = true}) async {
    try {
      String? token;
      if (withAuth) {
        token = await _resolveToken(retry: retry);
        if (token == null || token.isEmpty) {
          NavigationService.navigateToLogin(message: 'Session expired. Please sign in again.');
          return ApiResponse(success: false, statusCode: 401, errorMessage: 'Session expired. Please sign in again.');
        }
      }

      final headers = await _getHeaders(withAuth: withAuth, explicitToken: token);
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 401 && withAuth && retry) {
        final refreshed = await tryRefreshToken();
        if (refreshed) {
          return await post(url, body, withAuth: withAuth, retry: false);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, statusCode: 0, errorMessage: 'Network error: $e');
    }
  }

  static Future<ApiResponse> patch(String url, Map<String, dynamic> body, {bool withAuth = true, bool retry = true}) async {
    try {
      String? token;
      if (withAuth) {
        token = await _resolveToken(retry: retry);
        if (token == null || token.isEmpty) {
          NavigationService.navigateToLogin(message: 'Session expired. Please sign in again.');
          return ApiResponse(success: false, statusCode: 401, errorMessage: 'Session expired. Please sign in again.');
        }
      }

      final headers = await _getHeaders(withAuth: withAuth, explicitToken: token);
      final response = await http
          .patch(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 401 && withAuth && retry) {
        final refreshed = await tryRefreshToken();
        if (refreshed) {
          return await patch(url, body, withAuth: withAuth, retry: false);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, statusCode: 0, errorMessage: 'Network error: $e');
    }
  }

  static Future<ApiResponse> put(String url, Map<String, dynamic> body, {bool withAuth = true, bool retry = true}) async {
    try {
      String? token;
      if (withAuth) {
        token = await _resolveToken(retry: retry);
        if (token == null || token.isEmpty) {
          NavigationService.navigateToLogin(message: 'Session expired. Please sign in again.');
          return ApiResponse(success: false, statusCode: 401, errorMessage: 'Session expired. Please sign in again.');
        }
      }

      final headers = await _getHeaders(withAuth: withAuth, explicitToken: token);
      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 401 && withAuth && retry) {
        final refreshed = await tryRefreshToken();
        if (refreshed) {
          return await put(url, body, withAuth: withAuth, retry: false);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, statusCode: 0, errorMessage: 'Network error: $e');
    }
  }

  static Future<ApiResponse> delete(String url, {bool withAuth = true, bool retry = true}) async {
    try {
      String? token;
      if (withAuth) {
        token = await _resolveToken(retry: retry);
        if (token == null || token.isEmpty) {
          NavigationService.navigateToLogin(message: 'Session expired. Please sign in again.');
          return ApiResponse(success: false, statusCode: 401, errorMessage: 'Session expired. Please sign in again.');
        }
      }

      final headers = await _getHeaders(withAuth: withAuth, explicitToken: token);
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 401 && withAuth && retry) {
        final refreshed = await tryRefreshToken();
        if (refreshed) {
          return await delete(url, withAuth: withAuth, retry: false);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, statusCode: 0, errorMessage: 'Network error: $e');
    }
  }

  static Future<ApiResponse> postMultipart(
    String url,
    Map<String, String> fields, {
    String? fileField,
    String? fileName,
    List<int>? fileBytes,
    bool withAuth = true,
    bool retry = true,
  }) async {
    try {
      String? token;
      if (withAuth) {
        token = await _resolveToken(retry: retry);
        if (token == null || token.isEmpty) {
          NavigationService.navigateToLogin(message: 'Session expired. Please sign in again.');
          return ApiResponse(success: false, statusCode: 401, errorMessage: 'Session expired. Please sign in again.');
        }
      }

      final request = http.MultipartRequest('POST', Uri.parse(url));
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.fields.addAll(fields);
      if (fileField != null && fileName != null && fileBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName,
        ));
      }
      final streamedResponse = await request.send().timeout(const Duration(seconds: 12));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401 && withAuth && retry) {
        final refreshed = await tryRefreshToken();
        if (refreshed) {
          return await postMultipart(
            url,
            fields,
            fileField: fileField,
            fileName: fileName,
            fileBytes: fileBytes,
            withAuth: withAuth,
            retry: false,
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, statusCode: 0, errorMessage: 'Upload error: $e');
    }
  }

  static ApiResponse _handleResponse(http.Response response) {
    dynamic bodyData;
    try {
      bodyData = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      bodyData = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(
        success: true,
        statusCode: response.statusCode,
        data: bodyData,
      );
    }

    String errorMsg = 'An error occurred (${response.statusCode})';
    if (response.statusCode == 401) {
      errorMsg = 'Session expired. Please sign in again.';
      NavigationService.navigateToLogin(message: errorMsg);
    } else if (bodyData is Map) {
      if (bodyData.containsKey('detail')) {
        errorMsg = bodyData['detail'].toString();
      } else if (bodyData.containsKey('error')) {
        errorMsg = bodyData['error'].toString();
      } else if (bodyData.values.isNotEmpty) {
        final firstVal = bodyData.values.first;
        if (firstVal is List && firstVal.isNotEmpty) {
          errorMsg = firstVal.first.toString();
        } else {
          errorMsg = firstVal.toString();
        }
      }
    }
    return ApiResponse(
      success: false,
      statusCode: response.statusCode,
      data: bodyData,
      errorMessage: errorMsg,
    );
  }
}
